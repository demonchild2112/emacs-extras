; Set a policy for backup files.
(setq
   backup-by-copying t      ; don't clobber symlinks
   backup-directory-alist
   '(("." . "~/.saves"))    ; don't litter my fs tree
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t)       ; use versioned backups

; 2-space indent for shell scripts.
(defun gker-setup-sh-mode ()
   (interactive)
   (setq sh-basic-offset 2
      sh-indentation 2))
(add-hook 'sh-mode-hook 'gker-setup-sh-mode)

; Open symlink targets without confirmation.
(setq vc-follow-symlinks t)

; Disable electric indent.
(when (fboundp 'electric-indent-mode) (electric-indent-mode -1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Themes - At least emacs 24 required.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'custom-theme-load-path "/etc/emacs-extras/emacs-color-theme-solarized")

(add-to-list 'custom-theme-load-path "/etc/emacs-extras/dracula")

(load-theme 'dracula t)
