(defvar dm-source-dir (file-name-directory load-file-name))

;; To tidy up a buffer, created by simenheg
(defun tidy ()
  (interactive)
  (let ((beg (if (region-active-p) (region-beginning) (point-min)))
        (end (if (region-active-p) (region-end) (point-max))))
    (indent-region beg end)
    (whitespace-cleanup)
    (untabify beg (if (< end (point-max)) end (point-max)))))

;; Tidy all buffers that are not read-only
(defun tidy-all-buffers()
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (switch-to-buffer buffer) ; this is probably not necessary
      (when (eq buffer-read-only nil)
        (tidy)))))

;; Yank inside devilry-markdown code block
(defun dm-yank-java-block()
  (interactive)
  (let ((src (current-kill 0)))
    (insert (concat "```java\n" src "\n```\n"))))

;; Kill everything without saving
(defun desktop-hard-clear ()
  (interactive)
  (when (y-or-n-p (concat "Close all buffers without saving?"))
    (dolist (buffer (buffer-list))
      (let ((process (get-buffer-process buffer)))
        (when process (set-process-query-on-exit-flag process nil))
        (set-buffer buffer)
        (set-buffer-modified-p nil)
        (kill-this-buffer)))
    (delete-other-windows)))


;; Shows readme buffer if it exists
;; This is kind of horrible
(defun dm-show-readme()
  (mapc (lambda (buf)
          (when (eq (string-match "readme" (buffer-name buf)) 0)
            (switch-to-buffer buf)
            (read-only-mode)))
        (buffer-list)))

;; Inserts the template and adds username et end of first line
(defun dm-insert-template (username file-path)
  (insert-file-contents file-path)
  (move-end-of-line nil)
  (insert " - " username)
  (goto-char (point-max))
  (insert (concat "\nCorrected: " (current-time-string)))
  (goto-char (point-min)))


;; Create a new feedback file in the right folder
;; Splits windows and shows the previous feedback file
;; Opens all previous feedback files, but don't show them
(defun dm-create-new-and-show-old-feedback ()
  "Getting username from the the file path of the current buffer."
  ;; Ask until we get a valid username
  (let ((username (dm-get-username)))
    (while (not (yes-or-no-p (concat "Correcting \"" username "\" Is this a valid username?")))
      (when dm-easy-file-system
        (message (concat "The variable \"easy-file-system\" is currently \"t\""
                         "but the files are not organized this way.\n"
                         "Consider setting the variable \""
                         "easy-file-system to \"nil\" in devilry-mode.settings")))
      (setq username (read-string "Type the correct username: ")))

    (while (not (file-exists-p (concat dm-feedback-dir-path username)))
      (if (yes-or-no-p (concat "Can't find directory \"" dm-feedback-dir-path username "\". Create it?"))
          (make-directory (concat dm-feedback-dir-path username) t)
        (setq username (read-string
                        (concat "Please give a valid username. (Must be a folder in path \""
                                dm-feedback-dir-path "\"): ")))))

  ;; Calculate path to new and previous feedback file
    (let* ((user-feedback-dir (concat dm-feedback-dir-path username "/"))
           (newFilePath (concat user-feedback-dir dm-assignment-number ".md"))
           (prevFilePath (concat user-feedback-dir "/"
                                 (number-to-string (- (string-to-number dm-assignment-number) 1)) ".md")))

      ;; Split screen to open feedback files on the right
      (with-selected-window (split-window-right)

        ;; Open all feedback files in the background
        (dolist (file (directory-files user-feedback-dir t))
          (unless (file-directory-p file)
            (find-file-read-only file)
            (visual-line-mode)))

        ;; Create new feedback-file or open it if it exists
        (find-file newFilePath)
        (setq buffer-read-only nil)

        ;; Check if we have been editing this feedback file before
        (when (eq (buffer-size) 0)
          (dm-insert-template username dm-feedback-template-path))

        ;; Split window again if old feedback-file exists
        (when (file-exists-p prevFilePath)
          (with-selected-window (split-window-below)
            (find-file prevFilePath)
            (visual-line-mode)
            (goto-char (point-max))))

        ;; Activate visual-line-mode to make sure text wrap is good
        (visual-line-mode)))))


;; Try to compile .java files, shows eventual errors in new split window below.
;; It is the last modified window or something, tried to hack it. It somehow works
(defun dm-compile-all-open-java-files ()

  ;; Find the first java buffer, switch to it, compile all from there
  ;;  to make sure we are in the correct directory
  (dolist (buf (buffer-list))
    (let ((buf-name (buffer-name buf)))
      (when (string= (substring buf-name -5) ".java")
        (with-current-buffer buf
          (shell-command "javac *.java")

          ;; Show eventual errors from compilation in window below
          (if (> (buffer-size (get-buffer "*Shell Command Output*")) 0)
              (let ((output-window (split-window-below)))
                (message "Compilation gave errors.")

                (with-selected-window output-window
                  (pop-to-buffer-same-window "*Shell Command Output*")))

            ;; If compilation completed delete .class files
            (when dm-rm-class-files
              (message "Deleting class files.")
              (if (eq system-type 'windows-nt)
                  (shell-command "del *.class")
                (shell-command "rm *.class")))
            (message "Compilation completed sucessfully.")))
        (cl-return)))))


;; Compile all java files
;; Remove output .class files
;; Find README and switch to that buffer
(defun dm-do-oblig ()
  (interactive)
  (delete-other-windows)
  ;; Indent code automatically. Is set at the top of this file.
  (when dm-auto-indentation (tidy-all-buffers))
  ;; Create new and show previous feedback files on the right
  (dm-create-new-and-show-old-feedback)
  ;; Show readme if it exists
  (dm-show-readme)
  ;; Compile .java files
  (when dm-java-compilation
    (dm-compile-all-open-java-files)))

;; Writes updated data to file
(defun write-settings-file (file-path)
  ;; Construct data-string for file-insertion
  (let ((str (concat
              "feedback-dir-path "       dm-feedback-dir-path             "\n"
              "feedback-template-path "  dm-feedback-template-path        "\n"
              "assignment-number "       dm-assignment-number             "\n"
              "easy-file-system "        (symbol-name dm-easy-file-system) "\n"
              "rm-class-files "          (symbol-name dm-rm-class-files)   "\n"
              "java-compilation "        (symbol-name dm-java-compilation) "\n"
              "auto-indentation "        (symbol-name dm-auto-indentation))))
    ;; Write to file
    (write-region str nil file-path)
    (message "Updated settings file (devilry-mode.settings)")))

;; Get data from settings file
(defun dm-read-settings-file (file-path)
  ;; List of accepted keywords
  (let ((keywords (list "feedback-dir-path"
                        "feedback-template-path"
                        "easy-file-system"
                        "java-compilation"
                        "rm-class-files"
                        "auto-indentation"
                        "assignment-number")))
    ;; Create variables of the keywords with prefix dm-
    (dolist (keyword keywords)
      (set (intern (concat "dm-" keyword)) nil))
    ;; Set some default values
    (setq
     dm-easy-file-system          nil
     dm-java-compilation          t
     dm-rm-class-files            nil
     dm-auto-indentation          nil)
    ;; Read settings file and set variables
    (with-temp-buffer
      (when (file-exists-p file-path)
        (insert-file-contents file-path)
        ;; For each line on the file
        (dolist (line (split-string
                       (buffer-substring-no-properties
                        (point-min)
                        (point-max))
                       "\n" t))
          ;; Split line on space, set keyword to  first,
          (let ((keyword (car (split-string line " ")))
                (value (cl-reduce (lambda (x y) (concat x " " y))
                              (cdr (split-string line " ")))))
            (if (not (member keyword keywords))
                (message "ERROR: The keyword %s in the settings file is not a valid keyword." keyword)
              (if (null value)
                  (message "ERROR: The keyword %s in the settings file has no value." keyword)
                ;; Set the correct variable to t, nil or a string
                (message "Sat %s to %s" (intern (concat "dm-" keyword)) value)
                (set (intern (concat "dm-" keyword))
                     (cond ((string-equal value "t") t)
                           ((string-equal value "nil") nil)
                           (t value)))))))))))

;; Initiates the system
(defun dm-init ()
  (let ((settings-file (concat dm-source-dir "devilry-mode.settings")))
    (dm-read-settings-file settings-file)
    ;; Check if we need to write to file
    (let ((data-updated nil))
      ;; Check if not file exists
      (if (not (file-exists-p settings-file))
          (progn
            (setq dm-assignment-number
                  (read-string (concat "Settings file " settings-file " does not exist, creating it now:\n"
                                       "Assignment number: ")))
            (setq dm-feedback-dir-path
                  (read-directory-name "Path to feedback directory: "))
            (setq dm-feedback-template-path
                  (read-file-name "Path to feedback template: "))
            (setq data-updated t))

        ;; Check if user wants to update data
        (when (y-or-n-p (concat "Change assignment number? (is " dm-assignment-number ") "))
          (setq dm-assignment-number (read-string "Assignment number: "))
          (setq data-updated t))

        (when (y-or-n-p (concat "Change feedback directory? (is " dm-feedback-dir-path ") "))
          (setq dm-feedback-dir-path (read-directory-name "Path to feedback directory: "))
          (setq data-updated t))

        (when (y-or-n-p (concat "Change feedback template path? (is " dm-feedback-template-path ") "))
          (setq dm-feedback-template-path (read-file-name "Path to feedback template: "))
          (setq data-updated t)))

      ;; Check if the paths are valid, if not, ask to create directories
      (while (not (file-exists-p dm-feedback-dir-path))
        (if (yes-or-no-p (concat "Feedback directory does not exist (" dm-feedback-dir-path "). Create it? "))
            (make-directory dm-feedback-dir-path t)
          (setq dm-feedback-dir-path (read-directory-name "Path to feedback directory: "))))

      (while (not (file-exists-p dm-feedback-template-path))
        (if (yes-or-no-p (concat "Feedback template does not exist (" dm-feedback-template-path "). Create it? "))
            (progn
              ;; Creating feedback file, making sure the parent directories exist
              (let ((parent-dir (file-name-directory dm-feedback-template-path)))
                (unless (file-exists-p parent-dir)
                  (make-directory parent-dir t)))
              (write-region (concat "# INF1000 - Assignment " dm-assignment-number "\n"
                                    "## Exercise 1\n## Exercise 2\n## Exercise 3\n\n"
                                    "## Generally:\n\n\n### **Approved**")
                            nil dm-feedback-template-path))
          (setq dm-feedback-template-path (read-file-name "Path to feedback template: "))))

      ;; If we have new varables or could not find data we have to write to file
      (when data-updated
        (write-settings-file settings-file)))))

;; Self explanatory
(defun reverse-string (str)
  (apply
   'string
   (reverse (string-to-list str))))

;; Fetches username from the path of the current buffer file.
(defun dm-get-username ()

  ;; Support for windows backslash instead of slash.
  (let ((system-file-separator
         (if (eq system-type 'windows-nt)
             (string ?\\)
           "/")))
    (if dm-easy-file-system
        (reverse-string
         (nth 1
              (split-string (reverse-string (buffer-file-name)) system-file-separator)))
        (car
         (split-string
          (reverse-string
           (nth 2
                (split-string
                 (reverse-string (buffer-file-name))  system-file-separator))) " ")))))

;; The mode
(define-minor-mode devilry-mode
  nil
  :lighter " Devilry"
  :global t
  :init-value nil
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<f5>") 'dm-do-oblig)
            (define-key map (kbd "<f6>") 'desktop-hard-clear)
            (define-key map (kbd "C-, y") 'dm-yank-java-block)
            map)
  ;; This will be run every time the mode is toggled on or off
  ;; If we toggled the mode on, run init function
  (when (and devilry-mode (boundp 'devilry-mode))
    (dm-init)))

(provide 'devilry-mode)
