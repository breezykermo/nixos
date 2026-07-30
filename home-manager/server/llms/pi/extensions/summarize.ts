/**
 * Summarize command — uses claude-opus-4-8 to produce a structured summary
 * of the current conversation (goals, decisions, progress, next steps) and
 * displays it in a custom markdown UI panel.
 *
 * Depends on claude-opus-4-8. Falls back gracefully if the model or API key
 * is not available.
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import { complete, getModel } from "@earendil-works/pi-ai/compat";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder, getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, matchesKey, Text } from "@earendil-works/pi-tui";

type ContentBlock = { type?: string; text?: string; name?: string; arguments?: Record<string, unknown> };
type SessionEntry = { type: string; message?: { role?: string; content?: unknown } };

// ── helpers ────────────────────────────────────────────────────────────────

const extractTextParts = (content: unknown): string[] => {
    if (typeof content === "string") return [content];
    if (!Array.isArray(content)) return [];
    const parts: string[] = [];
    for (const part of content) {
        if (!part || typeof part !== "object") continue;
        const b = part as ContentBlock;
        if (b.type === "text" && typeof b.text === "string") parts.push(b.text);
    }
    return parts;
};

const extractToolCalls = (content: unknown): string[] => {
    if (!Array.isArray(content)) return [];
    const calls: string[] = [];
    for (const part of content) {
        if (!part || typeof part !== "object") continue;
        const b = part as ContentBlock;
        if (b.type !== "toolCall" || typeof b.name !== "string") continue;
        calls.push(`Tool ${b.name} was called with args ${JSON.stringify(b.arguments ?? {})}`);
    }
    return calls;
};

const buildConversationText = (entries: SessionEntry[]): string => {
    const sections: string[] = [];
    for (const entry of entries) {
        if (entry.type !== "message" || !entry.message?.role) continue;
        const role = entry.message.role;
        if (role !== "user" && role !== "assistant") continue;

        const lines: string[] = [];
        const textParts = extractTextParts(entry.message.content);
        if (textParts.length > 0) {
            lines.push(`${role === "user" ? "User" : "Assistant"}: ${textParts.join("\n").trim()}`);
        }
        if (role === "assistant") lines.push(...extractToolCalls(entry.message.content));

        if (lines.length > 0) sections.push(lines.join("\n"));
    }
    return sections.join("\n\n");
};

const SUMMARY_PROMPT = [
    "Summarize this conversation so I can resume it later.",
    "Include goals, key decisions, progress, open questions, and next steps.",
    "Keep it concise and structured with headings.",
    "",
    "<conversation>",
].join("\n");

const showSummaryUi = async (summary: string, ctx: ExtensionCommandContext) => {
    if (ctx.mode !== "tui") return;
    await ctx.ui.custom((_tui, theme, _kb, done) => {
        const container = new Container();
        const border = new DynamicBorder((s: string) => theme.fg("accent", s));
        const mdTheme = getMarkdownTheme();

        container.addChild(border);
        container.addChild(new Text(theme.fg("accent", theme.bold("Conversation Summary")), 1, 0));
        container.addChild(new Markdown(summary, 1, 1, mdTheme));
        container.addChild(new Text(theme.fg("dim", "Press Enter or Esc to close"), 1, 0));
        container.addChild(border);

        return {
            render: (w: number) => container.render(w),
            invalidate: () => container.invalidate(),
            handleInput: (data: string) => {
                if (matchesKey(data, "enter") || matchesKey(data, "escape")) done(undefined);
            },
        };
    });
};

// ── entry point ────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
    pi.registerCommand("summarize", {
        description: "Summarize the current conversation in a custom markdown UI panel",
        handler: async (_args: string, ctx: ExtensionCommandContext) => {
            const thread = ctx.sessionManager.getBranch();
            const conversationText = buildConversationText(thread);

            if (!conversationText.trim()) {
                if (ctx.hasUI) ctx.ui.notify("No conversation text to summarize", "warning");
                return;
            }

            if (ctx.hasUI) ctx.ui.notify("Preparing summary...", "info");

            const model = getModel("anthropic", "claude-opus-4-8");
            if (!model) {
                ctx.ui?.notify("Model claude-opus-4-8 not available", "warning");
                return;
            }

            const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
            if (!auth?.ok || !auth.apiKey) {
                ctx.ui.notify(auth.error ?? "No API key for claude-opus-4-8", "warning");
                return;
            }

            const response = await complete(
                model,
                { messages: [{ role: "user" as const, content: [{ type: "text" as const, text: SUMMARY_PROMPT + "\n" + conversationText + "\n</conversation>" }] }] },
                { apiKey: auth.apiKey, headers: auth.headers, cacheRetention: "none", sessionId: uuidv7() }
            );

            const summary = response.content
                .filter((c): c is { type: "text"; text: string } => c.type === "text" && typeof c.text === "string")
                .map((c) => c.text)
                .join("\n");

            await showSummaryUi(summary, ctx);
        },
    });
}
