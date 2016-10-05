(defparameter *open* '())
(defparameter *memory* '())
(defparameter *id* 0)
(defparameter *ops* '((:GranjeroSolo (1 0 0 0))
		     (:Granjero-Lobo (1 1 0 0))
		     (:Granjero-Oveja (1 0 1 0))
		     (:Granjero-Legumbres (1 0 0 1))))
(defparameter  *current-ancestor*  nil)
(defparameter  *solucion*  nil)
(defparameter *contadorNodos* 0)
(defparameter *contadorExpandir* 0)
(defparameter *contadorFronteraBusqueda* 0)
(defparameter *tiempoInicial* 0)
(defparameter *tiempoFinal* 0)

(defun create-node (estado operador)
  (incf *id*)
  (incf *contadorNodos*)
  (list (1- *id*) estado *current-ancestor* (first operador)))

(defun barge-shore (estado)
  (if (= 1 (fifth (first estado))) 0 1))

(defun insert-to-open (estado operador metodo)
  (let ((nodo (create-node estado operador)))
    (cond ((equal metodo :depth-first)
						(push nodo *open*))
	  			((equal metodo :breath-first)
						(setq *open* (append *open* (list nodo))))
	  			(T Nil))))

(defun get-from-open ()
  (pop *open*))

(defun valid-operator (operador estado)
  (let* ((orilla (barge-shore estado))
	 (granjero (first (nth orilla estado)))
	 (lobo (second (nth orilla estado)))
	 (oveja (third (nth orilla estado)))
	 (legumbres (fourth (nth orilla estado))))
    (or (= granjero (first (second operador)))
	 (= lobo (second (second operador)))
	 (= oveja (third (second operador)))
	 (= legumbres (fourth (second operador))))))

(defun valid-state (estado)
  (let ((orilla1 (first estado))
	(orilla2 (second estado)))
    (and (not (equal orilla1 '(0 1 1 0 0))) (not (equal orilla2 '(0 1 1 0 0))) (not (equal orilla1 '(0 0 1 1 0))) (not (equal orilla2 '(0 0 1 1 0))))))

(defun flip (bit)
  (boole  BOOLE-XOR  bit  1))

(defun apply-operator (operador estado)
  (let* ((orilla1 (first estado))
	 (orilla2 (second estado))
	 (g0 (first orilla1))
	 (l0 (second orilla1))
	 (ov0 (third orilla1))
	 (leg0 (fourth orilla1))
	 (b0 (fifth orilla1))
	 (g1 (first orilla2))
	 (l1 (second orilla2))
	 (ov1 (third orilla2))
	 (leg1 (fourth orilla2))
	 (b1 (fifth orilla2))
	 (orilla-barco (barge-shore estado))
	 (op (first operador)))
    (case op
      (:GranjeroSolo (if (= orilla-barco 0)
			 (list (list 0 l0 ov0 leg0 0) (list 1 l1 ov1 leg1 1))
			 (list (list 1 l0 ov0 leg0 1) (list 0 l1 ov1 leg1 0))))
      (:Granjero-Lobo (if (= orilla-barco 0)
			  (list (list 0 0 ov0 leg0 0) (list 1 1 ov1 leg1 1))
			  (list (list 1 1 ov0 leg0 1) (list 0 0 ov1 leg1 0))))
      (:Granjero-Oveja (if (= orilla-barco 0)
			   (list (list 0 l0 0 leg0 0) (list 1 l1 1 leg1 1))
			   (list (list 1 l0 1 leg0 1) (list 0 l1 0 leg1 0))))
      (:Granjero-Legumbres (if (= orilla-barco 0)
			       (list (list 0 l0 ov0 0 0) (list 1 l0 ov0 1 1))
			       (list (list 1 l0 ov0 1 1) (list 0 l0 ov0 0 0))))
      (T "Error"))))

(defun expand (estado)
  (incf *contadorExpandir*)
  (let ((descendientes nil)
	(nuevo-estado nil))
    (dolist (op *ops* descendientes)
      (setq nuevo-estado (apply-operator op estado))
      (when (and (valid-operator op estado)
		 (valid-state nuevo-estado))
	(setq descendientes (cons (list nuevo-estado op) descendientes))))))

(defun remember-state (estado memoria)
  (cond ((null memoria) nil)
	((equal estado (second (first memoria))) T)
	(T (remember-state estado (rest memoria)))))

(defun  filter-memories (lista-estados-y-ops)
     (cond ((null  lista-estados-y-ops)  Nil)
	       ((remember-state (first (first  lista-estados-y-ops)) *memory*)
		       (filter-memories  (rest  lista-estados-y-ops)))
		(T  (cons  (first lista-estados-y-ops) (filter-memories  (rest  lista-estados-y-ops))))) )

(defun extract-solution (nodo)
  (labels ((locate-node (id lista)
	     (cond ((null lista) Nil)
		   ((equal id (first (first lista))) (first lista))
		   (T (locate-node id (rest lista))))))
    (let ((current (locate-node (first nodo) *memory*)))
      (loop while (not (null current)) do
	   (push current *solucion*)
	   (setq current (locate-node (third current) *memory*))))
    *solucion*))

(defun display-solution (lista-nodos)
  (setq *tiempoFinal* (get-internal-real-time))
  (format  t "Nodos creados ~A ~%" *contadorNodos*)
  (format  t "Nodos expandidos ~A ~%" *contadorExpandir*)
  (format  t "Longitud maxima de frontera de busqueda ~A ~%" *contadorFronteraBusqueda*)
  (format  t "Tiempo para encontrar la solucion: ~A~%" (/ (- *tiempoFinal* *tiempoInicial*) internal-time-units-per-second))
  (format  t  "Solucion con ~A  pasos~%" (1- (length  lista-nodos)))
  (let ((nodo nil))
    (dotimes (i (length lista-nodos))
      (setq nodo (nth i lista-nodos))
      (if (= i 0)
	  (format t "Inicio en: ~A~%" (second  nodo))
	  (format t "\(~A\) aplicando ~A  se  llega  a  ~A~%"  i (fourth  nodo)  (second  nodo))))))

(defun reset-all ()
  (setq  *open*  nil)
  (setq  *memory*  nil)
  (setq  *id*  0)
  (setq *contadorNodos* 0)
  (setq *contadorExpandir* 0)
  (setq *contadorFronteraBusqueda* 0)
  (setq *tiempoInicial* 0)
  (setq *tiempoFinal* 0)
  (setq  *current-ancestor*  nil)
  (setq  *solucion*  nil))

(defun blind-search (inicial final metodo)
  (reset-all)
  (setq *tiempoInicial* (get-internal-real-time))
  (let ((nodo nil)
	(estado nil)
	(sucesores '())
	(operador nil)
	(meta-encontrada nil))
    (insert-to-open inicial nil metodo)
    (loop until (or meta-encontrada (null *open*)) do
	 (setq nodo (get-from-open)
	       estado (second nodo)
	       operador (third nodo))
	 (push nodo *memory*)
	 (incf *contadorFronteraBusqueda*)
	 (cond ((equal final estado)
		(format  t  "Exito. Meta encontrada en ~A  intentos~%" (first  nodo))
		(display-solution (extract-solution nodo))
		(setq meta-encontrada T))
	       (T (setq *current-ancestor* (first nodo))
		  (setq sucesores (expand estado))
		  (setq sucesores (filter-memories sucesores))
		  (loop for element in sucesores do
		       (insert-to-open (first element) (second element) metodo)))))))

(blind-search '((1 1 1 1 1)(0 0 0 0 0)) '((0 0 0 0 0)(1 1 1 1 1)) :depth-first)
(blind-search '((1 1 1 1 1)(0 0 0 0 0)) '((0 0 0 0 0)(1 1 1 1 1)) :breath-first)
