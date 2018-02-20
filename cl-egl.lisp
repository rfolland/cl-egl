
(in-package :egl)

(define-foreign-library libegl
  (t (:default "libEGL")))

(use-foreign-library libegl)

(defctype EGLBoolean :uint)
(defctype EGLDisplay :pointer)
(defctype EGLConfig :pointer)
(defctype EGLSurface :pointer)
(defctype EGLContext :pointer)
(defctype EGLint :int32)

(defcenum (eglenum EGLint)
  (:surface-type #x3033)
  (:window-bit #x0004)
  (:red-size #x3024)
  (:blue-size #x3022)
  (:green-size #x3023)
  (:depth-size #x3025)
  (:renderable-type #x3040)
  (:opengl-bit #x0008)
  (:opengl-es-bit #x0001)
  (:opengl-api #x30A2)
  (:opengl-es-api #x30A0)
  (:context-major-version #x3098)
  (:context-minor-version #x30FB)
  (:none #x3038))

(defcfun ("eglGetError" get-error) EGLint)

(defcfun ("eglGetDisplay" get-display) EGLDisplay
  (display-id :pointer))

(defcfun "eglInitialize" EGLBoolean
  (display EGLDisplay)
  (major :pointer)
  (minor :pointer))

(defcfun "eglGetProcAddress" :pointer
  (procname :string))

(defconstant EGL_PLATFORM_GBM_KHR #x31D7)

(defun get-platform-display (device)
  (foreign-funcall-pointer (eglGetProcAddress (convert-to-foreign "eglGetPlatformDisplayEXT"
                                                                  '(:pointer :char)))
                           ()
                           EGLint EGL_PLATFORM_GBM_KHR
                           :pointer device
                           :pointer (ccl:%null-ptr)
                           EGLDisplay))

(defun initialize (display)
  (with-foreign-objects
      ((major 'EGLint 1)
       (minor 'EGLint 1))
    (when (= (eglInitialize display major minor) 0)
      (terminate display)
      (error "Failed to initialize EGL with code ~d" (get-error))
      )
    (format t "~A~%" (get-error))
    (values (mem-aref major 'EGLint)
	    (mem-aref minor 'EGLint))))

(defcfun "eglChooseConfig" EGLBoolean
  (display EGLDisplay)
  (attrib-list (:pointer EGLint))
  (configs (:pointer EGLConfig))
  (config-size EGLint)
  (num-config (:pointer EGLint)))

(defun choose-config (display config-size &rest config-attribs)
  (with-foreign-objects
      ((requested-attribs 'EGLint (length config-attribs))
       (available-configs '(:pointer EGLConfig) 1)
       (num-configs 'EGLint 1))
    (loop :for i :from 0 :to (- (length config-attribs) 1)
       :do (setf (mem-aref requested-attribs 'EGLint i)
		 (if (keywordp (nth i config-attribs))
		     (foreign-enum-value 'eglenum (nth i config-attribs))
		     (nth i config-attribs))))
    (eglchooseconfig display requested-attribs available-configs config-size num-configs)
    (loop :for i :from 0 :to (- (mem-aref num-configs 'EGLint) 1)
       :collecting (mem-aref available-configs :pointer i))))

(defcfun "eglCreateContext" EGLContext
  (display EGLDisplay)
  (config EGLConfig)
  (share-context EGLContext)
  (attrib-list (:pointer EGLint)))

(defun create-context (display config share-context &rest attribs)
  (with-foreign-objects
      ((requested-attribs 'EGLint (length attribs)))
    (loop :for i :from 0 :to (- (length attribs) 1)
       :do (setf (mem-aref requested-attribs 'EGLint i)
		 (if (keywordp (nth i attribs))
		     (foreign-enum-value 'eglenum (nth i attribs))
		     (nth i attribs))))
    (eglcreatecontext display config share-context requested-attribs)))

(defcfun ("eglCreateWindowSurface" create-window-surface) EGLSurface
  (display EGLDisplay)
  (config EGLConfig)
  (win :pointer)
  (attrib-list (:pointer EGLint)))

(defcfun ("eglTerminate" terminate) EGLBoolean
  (display EGLDisplay))

(defcfun "eglBindAPI" EGLBoolean
  (api :uint))

(defun bind-api (api)
  (eglbindapi (foreign-enum-value 'eglenum api)))
  
(defcfun ("eglMakeCurrent" make-current) EGLBoolean
  (display EGLDisplay)
  (draw EGLSurface)
  (read EGLSurface)
  (context EGLContext))

(defcfun ("eglSwapBuffers" swap-buffers) EGLBoolean
  (display EGLDisplay)
  (surface EGLSurface))

(defcfun ("eglDestroySurface" destroy-surface) EGLBoolean
  (display EGLDisplay)
  (surface EGLSurface))

(defcfun ("eglDestroyContext" destroy-context) EGLBoolean
  (display EGLDisplay)
  (context EGLContext))

(defcfun ("eglQueryString" query-string) (:pointer :char)
  (display EGLDisplay)
  (name EGLInt))

