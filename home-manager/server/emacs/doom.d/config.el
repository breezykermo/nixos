;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq basep "/home/alice")
;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Lachlan Kermode"
      user-mail-address "lachiekermode@gmail.com")

;; FONTS, THEME et al
(setq doom-font (font-spec :family "Liberation Mono" :size 20)
       doom-variable-pitch-font (font-spec :family "Hack" :size 20))
(set-frame-parameter (selected-frame) 'alpha '(100 50))

(setq doom-theme 'doom-one)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))

(set-face-attribute 'default nil :height 120)
(setq display-line-numbers-type t)

;; ORG
(setq PKB_DIR (format "%s/Dropbox (Brown)/lyt" basep))
(setq org-directory PKB_DIR)
(setq org-deadline-warning-days 3)
(after! org
        (setq org-log-done 'time) ;; add timestamps to DONE
        (setq org-default-notes-file (format "%s/Dropbox (Brown)/lyt/org/notes.org" basep))
)

(after! citar
  (setq! citar-bibliography '(format "%s/Dropbox (Brown)/lyt/references/master.bib" basep)))

;; REMAPS
(map! "C-}"             #'next-buffer)
(map! "C-t"             #'previous-buffer)

(map! :desc "Vim-like window movement up"
      "C-k"             #'evil-window-up)
(map! :desc "Vim-like window movement down"
      "C-j"             #'evil-window-down)
(map! :desc "Vim-like window movement left"
      "C-h"             #'evil-window-left)
(map! :desc "Vim-like window movement right"
      "C-l"             #'evil-window-right)
(map! :leader
      (:prefix ("w" . "window")
      :desc "Tmux-like window split"
      "c"               #'evil-window-split))
(map! :leader
      :desc "Faster access of agenda"
      "a"               #'org-agenda-list)

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox")
