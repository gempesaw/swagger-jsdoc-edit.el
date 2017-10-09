;;; swagger-jsdoc-edit.el --- pop out a buffer to compose valid swagger yaml  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Daniel Gempesaw

;; Author: Daniel Gempesaw <dgempesaw@sharecare.com>
;; Keywords: convenience, tools
;; Version: 1.0.0
;; Package-Requires: ((dash "2.13.0") (s "1.10.0") (f "0.19.0") (yaml-mode "0.0.13"))
;; URL: https://github.com/gempesaw/swagger-jsdoc-edit.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; swagger-jsdoc-edit creates a workflow for editing yaml swagger path
;; partial entries written in jsdoc comment format. When the point is
;; in a jsdoc yaml comment, invoke `sje/edit-swagger` and we'll pop a
;; new buffer in yaml mode for you. Edit your yaml freely, validate
;; progressively with `sje/validate-swagger`, and when you're finished
;; with your edits, invoke `sje/update-swagger` to replace the old
;; jsdoc comment with the updated yaml, properly formatted and
;; everything.

;;; Code:

(require 's)
(require 'dash)
(require 'f)
(require 'yaml-mode)

(defvar sje/edit-buffer "*sje-edit*")
(defvar sje/main-buffer nil)
(defvar sje/window-configuration nil)
(defvar sje/region '())
(defvar sje/swagger-tools-binary (executable-find "swagger-tools"))
(defvar sje/edit-shortcut (kbd "C-c C-c"))
(defvar sje/js-keymap (make-sparse-keymap))

(defun sje/edit-swagger ()
  (interactive)
  (let* ((beg (or (search-backward "/**" nil t) (line-beginning-position)))
         (end (or (search-forward "*/" nil t) (line-end-position)))
         (yaml (sje/jsdoc-to-yaml (buffer-substring-no-properties beg end)))
         (yaml-buffer (get-buffer-create sje/edit-buffer)))
    (setq sje/window-configuration (current-window-configuration))
    (setq sje/main-buffer (current-buffer))
    (setq sje/region `(,beg ,end))
    (with-current-buffer yaml-buffer
      (erase-buffer)
      (insert yaml)
      (pop-to-buffer yaml-buffer)
      (yaml-mode)
      (sje/edit-mode))))

(defun sje/jsdoc-to-yaml (jsdoc)
  (s-join "\n" (--map (s-chop-prefix " \* " it)
                      (--filter (s-match " \* [^@\*]" it)
                                (s-split "\n" jsdoc)))))

(defun sje/yaml-to-jsdoc (yaml)
  (let ((surrounding '("/**" " * @swagger" " */")))
    (s-join "\n"
            (-flatten
             (-insert-at 2 (--map (s-concat " * " it)
                                  (s-split "\n" yaml))
                         surrounding)))))

(defun sje/validate-swagger ()
  (interactive)
  (if sje/swagger-tools-binary
      (let* ((command "validate")
             (file (make-temp-file "sje"))
             (yaml (buffer-substring-no-properties (point-min) (point-max)))
             (preamble (s-join "\n" '("swagger: \"2.0\"" "info:" "  version: version" "  title: title" "host: host" "basePath: /basePath" "paths:" "")))
             (swagger (s-concat preamble (s-join "\n" (--map (s-prepend "  " it) (s-split "\n" yaml)))))
             (result))
        (f-write-text swagger 'utf-8 file)
        (setq result (shell-command-to-string
                      (format "%s %s %s" sje/swagger-tools-binary command file)))
        (f-delete file t)
        (if (string= "" result)
            (message "swagger 2.0 schema validated!")
          (error result)))
    (message "could not find swagger-tools, cannot do validation")))

(defun sje/update-swagger ()
  (interactive)
  (let ((jsdoc (sje/yaml-to-jsdoc (buffer-substring-no-properties (point-min) (point-max)))))
    ;; (when sje/swagger-tools-binary
    ;;   (sje/validate-swagger))
    (kill-buffer sje/edit-buffer)
    (with-current-buffer sje/main-buffer
      (apply 'delete-region sje/region)
      (goto-char (car sje/region))
      (insert jsdoc))
    (set-window-configuration sje/window-configuration)))

(defun sje/update-bindings ()
  (setq sje/js-keymap (make-sparse-keymap))
  (define-key sje/js-keymap sje/edit-shortcut #'sje/edit-swagger))
(sje/update-bindings)

(defvar sje/edit-keymap (make-sparse-keymap))
(define-key sje/edit-keymap (kbd "M-s") #'sje/update-swagger)
(define-key sje/edit-keymap (kbd "C-c C-c") #'sje/update-swagger)
(define-key sje/edit-keymap (kbd "C-c C-v") #'sje/validate-swagger)

(define-minor-mode sje/js-mode
  "Minor mode for invoking swagger edit popout commands"
  nil
  "sje/js"
  sje/js-keymap
  (sje/update-bindings))

(define-minor-mode sje/edit-mode
  "Minor mode for invoking swagger edit popout commands"
  nil
  "sje/edit"
  sje/edit-keymap)

(provide 'swagger-jsdoc-edit)
;;; swagger-jsdoc-edit.el ends here
