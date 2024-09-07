;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq basep "/home/alice")
(setq user-full-name "Lachlan Kermode"
      user-mail-address "lachiekermode@gmail.com")

;; FONTS, THEME et al
(setq doom-font (font-spec :family "Fira Code" :size 20)
       doom-variable-pitch-font (font-spec :family "Fira Code" :size 20))
(set-frame-parameter (selected-frame) 'alpha '(100 50))

(setq doom-theme 'doom-gruvbox)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))

(set-face-attribute 'default nil :height 120)
(setq display-line-numbers-type t)

;; Set background color to none to respect terminal transparency
(custom-set-faces
 '(default ((t (:background "unspecified-bg"))))
 '(fringe ((t (:background "unspecified-bg"))))
 '(line-number ((t (:background "unspecified-bg"))))
 '(line-number-current-line ((t (:background "unspecified-bg")))))

;; ORG
;; XXX https://so.nwalsh.com/2020/01/05-latex
(after! org
        (setq org-latex-pdf-process
              '("tectonic --keep-intermediates --reruns 0 %f")) ; use tectonic rather than latex
        (setq org-log-done 'time) ;; add timestamps to DONE
        (setq org-default-notes-file (format "%s/Dropbox (Brown)/lyt/org/notes.org" basep))
        ;; LaTeX export classes
        (add-to-list 'org-latex-classes
             '("acmart"
               "letter"
               ("\\chapter{%s}" . "\\chapter*{%s}")
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")       
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
             )
          ;; Default LaTeX export packages
          ;; (add-to-list 'org-export-latex-packages-alist '("" ))
          (setq org-deadline-warning-days 3))

(after! citar
  (setq! citar-bibliography '(format "%s/Dropbox (Brown)/lyt/references/master.bib" basep)))

;; ;; Modify =emphasis= in PDFs
;; (add-to-list 'org-emphasis-alist
;;              '("=" (:foreground "blue")))
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

(load custom-file)
