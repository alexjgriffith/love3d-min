(local mat4 {})

(local (m1 m2 m3)
       (values [1 1 0 0
                1 1 0 0
                1 1 0 0
                1 1 0 0]
               [1 1 1 1
                1 1 1 1
                0 0 0 0
                0 0 0 0]
               [2 0 0 0
                0 2 0 0
                0 0 2 0
                0 0 0 2]))

(fn mat4.identity []
  [1 0 0 0
   0 1 0 0
   0 0 1 0
   0 0 0 1])

(fn mat4.zeros []
  [0 0 0 0
   0 0 0 0
   0 0 0 0
   0 0 0 0])


(fn mat4.multiply [m1 m2]
  (local out [])
  (for [i 0 3]
    (for [j 0 3]
      (table.insert
       out
       (+ (* (. m1 (+ 1 (* i 4)))
             (. m2 (+ 1 j)))
          (* (. m1 (+ 2 (* i 4)))
             (. m2 (+ 5 j)))
          (* (. m1 (+ 3 (* i 4)))
             (. m2 (+ 9 j)))
          (* (. m1 (+ 4 (* i 4)))
             (. m2 (+ 13 j)))))))
    out
    )

(fn mat4.copy [m1]
  (icollect [v i (ipairs m1)] i))

(fn mat4.concat [m1 m2]
  (local out [])
  (for [x 0 15]
    (let [i (math.floor (/ x 4))
          j (math.floor (% x 4))]
      (tset out (+ (* i 8) j 1) (. m1 (+ (* 4 i) j 1)))
      (tset out (+ (* i 8) j 5) (. m2 (+ (* 4 i) j 1)))
      )
    )
  out
  )

;; WIP
;; https://github.com/davidm/lua-matrix/blob/master/lua/matrix.lua
;; (fn mat4.invert [m1]
;;   (let [m2 (mat4.concat m1 (mat4.identity))
;;         (match  (mat4.dogauss m2)
;;           true  (mat4.subm m2, 1, 3, 4, 4)
;;           (false rank) (values nil rank)
;;           )
;;         ]
    
;;     )
;;   )

(fn mat4.transpose! [m]
  (fn swap [m i j]
    (let [tmp (. m i)]
    (tset m i (. m j))
    (tset m j tmp)))
  (swap m 2 5)
  (swap m 3 9)
  (swap m 4 13)
  (swap m 7 10)
  (swap m 8 14)
  (swap m 12 15)
  m
  )


(fn mat4.transpose [min]
  (local m [])
  (each [_ v (ipairs min)]
    (table.insert m v))
  (fn swap [m i j]
    (let [tmp (. m i)]
    (tset m i (. m j))
    (tset m j tmp)))
  (swap m 2 5)
  (swap m 3 9)
  (swap m 4 13)
  (swap m 7 10)
  (swap m 8 14)
  (swap m 12 15)
  m
  )


(fn mat4.perspective-rhno! [_ fov aspect near far]
  "
[A 0 0 0
 0 B 0 0
 0 0 C 1
 0 0 D 0]
"
  (local f  (math.tan (* (/ fov 2)) (/ 180 math.pi)))
  [ (/ 1 (* f aspect)) 0 0 0
    0  (/ 1 f) 0 0
    0 0 (- (/ (+ far  near) (- far near))) 1
    0 0 (- (/ (* 2  far near) (- far near))) 0
    ]
  )


(fn mat4.perspective-rhzo! [_ fov aspect near far]
  "
[A 0 0 0
 0 B 0 0
 0 0 C 1
 0 0 D 0]
"
  (local f  (math.tan (* (/ fov 2)) (/ 180 math.pi)))
  [ (/ 1 (* f aspect)) 0 0 0
    0  (/ 1 f) 0 0
    0 0 (/ far (- near far)) -1
    0 0 (- (/ (* far near) (- far near))) 0
    ]
  )


;; https://github.com/g-truc/glm/blob/master/glm/ext/matrix_clip_space.inl
;; RHZO
;; Result[0][0] = static_cast<T>(1) / (aspect * tanHalfFovy);
;; Result[1][1] = static_cast<T>(1) / (tanHalfFovy);
;; Result[2][2] = zFar / (zNear - zFar);
;; Result[2][3] = - static_cast<T>(1);
;; Result[3][2] = -(zFar * zNear) / (zFar - zNear);
;; LHNO
;; mat<4, 4, T, defaultp> Result(static_cast<T>(0));
;; Result[0][0] = static_cast<T>(1) / (aspect * tanHalfFovy);
;; Result[1][1] = static_cast<T>(1) / (tanHalfFovy);
;; Result[2][2] = (zFar + zNear) / (zFar - zNear);
;; Result[2][3] = static_cast<T>(1);
;; Result[3][2] = - (static_cast<T>(2) * zFar * zNear) / (zFar - zNear);
;; RHNO
;; mat<4, 4, T, defaultp> Result(static_cast<T>(0));
;; Result[0][0] = static_cast<T>(1) / (aspect * tanHalfFovy);
;; Result[1][1] = static_cast<T>(1) / (tanHalfFovy);
;; Result[2][2] = - (zFar + zNear) / (zFar - zNear);
;; Result[2][3] = - static_cast<T>(1);
;; Result[3][2] = - (static_cast<T>(2) * zFar * zNear) / (zFar - zNear);
(fn mat4.perspective-lhno! [_ fov aspect near far]
  "
[A 0 0 0
 0 B 0 0
 0 0 C 1
 0 0 D 0]
"
  (local f  (math.tan (* (/ fov 2)) (/ 180 math.pi)))
  [ (/ 1 (* f aspect)) 0 0 0
    0  (/ 1 f) 0 0
    0 0 (/ (+ far  near) (- far near)) 1
    0 0 (- (/ (* 2  far near) (- far near))) 0
    ]
  )


(fn mat4.ortho! [matrix left right bottom top near far]
  "
[A 0 0 B
 0 C 0 D
 0 0 E F
 0 0 0 1]
"
  (tset matrix 1 (/ 2 (- right left)))
  (tset matrix 6 (/ 2 (- top bottom)))
  (tset matrix 11 (/ 2 (- far near)))
  (tset matrix 4 (- (/ (+ right left) (- right left))))
  (tset matrix 8 (- (/ (+ top bottom) (- top bottom))))
  (tset matrix 12 (- (/ (+ far near) (- far near))))
  matrix
  )

(fn mat4.model-transform [translation scale rotation]
  (local {: cos : sin} math)
  (let [c3 (cos (. rotation 3))
        s3 (sin (. rotation 3))
        c2 (cos (. rotation 1))
        s2 (sin (. rotation 1))
        c1 (cos (. rotation 2))
        s1 (sin (. rotation 2))
        sx (. scale 1)
        sy (or (. scale 2) sx)
        sz (or (. scale 3) sx)
        tx (. translation 1)
        ty (. translation 2)
        tz (. translation 3)]
    [(+ (* sx s1 s2 s3) (* sx c1 c3)) (- (* sy c3 s1 s2) (* sy c1 s3)) (* sz c2 s1)  tx
     (* sx c2 s3)                     (* sy c2 c3)                     (- (* sz s2)) ty
     (- (* sx c1 s2 s3) (* sx s1 c3)) (+ (* sy c1 c3 s2) (* sy s1 s3)) (* sz c1 c2)  tz
     0                                0                                0             1.0
     ]))

(local vec3 {})

(fn vec3.magnitude [vec]
  (math.sqrt (+ (^ (. vec 1) 2) (^ (. vec 2) 2) (^ (. vec 3) 2))))

(fn vec3.normalize [vec]
  (let [m (vec3.magnitude vec)]
    [(/ (. vec 1) m)
     (/ (. vec 2) m)
     (/ (. vec 3) m)]))

(fn vec3.cross [v1 v2]
  [(- (* (. v1 2) (. v2 3)) (* (. v1 3) (. v2 2)))
   (- (* (. v1 3) (. v2 1)) (* (. v1 1) (. v2 3)))
   (- (* (. v1 1) (. v2 2)) (* (. v1 2) (. v2 1)))])

(fn vec3.dot [v1 v2]
  (+ (* (. v1 1) (. v2 1))
     (* (. v1 2) (. v2 2))
     (* (. v1 3) (. v2 3))
     ))

(fn vec3.subtract [v1 v2]
  [(- (. v1 1) (. v2 1))
   (- (. v1 2) (. v2 2))
   (- (. v1 3) (. v2 3))
   ])


(fn mat4.homogenize [m]
  (fn b [index mag]
    (/ (. m index) mag))
  (let [c1 (. m 13)
        c1p (if (~= 0 c1) c1 1)
        c2 (. m 14)
        c2p (if (~= 0 c2) c2 1)
        c3 (. m 15)
        c3p (if (~= 0 c3) c3 1)
        c4 (. m 16)
        c4p (if (~= 0 c3) c4 1)
        ]
    [(b 1 c1p) (b 2 c2p) (b 3 c3p) (b 4 c4p)
     (b 5 c1p) (b 6 c2p) (b 7 c3p) (b 8 c4p)
     (b 9 c1p) (b 10 c2p) (b 11 c3p) (b 12 c4p)
     (b 13 c1p) (b 14 c2p) (b 15 c3p) (b 16 c4p)]
    ))

(fn mat4.vec3multiply [m v]
  ;;(local m (mat4.homogenize min))
  [(+ (* (. v 1) (. m 1))
      (* (. v 2) (. m 2))
      (* (. v 3) (. m 3))
      (* 1 (. m 4)))
   (+ (* (. v 1) (. m 5))
      (* (. v 2) (. m 6))
      (* (. v 3) (. m 7))
      (* 1 (. m 8)))
   (+ (* (. v 1) (. m 9))
      (* (. v 2) (. m 10))
      (* (. v 3) (. m 11))
      (* 1 (. m 12)))
   (+ (* 1 (. m 13))
      (* 1 (. m 14))
      (* 1 (. m 15))
      (* 1 (. m 16)))])


(fn mat4.view-direction [position direction up?]
  (local up-default [0 -1 0])
  (let [up (or up? up-default)
        w (vec3.normalize direction)
        u (vec3.normalize (vec3.cross w up))
        v (vec3.cross w u)
        nw (- (vec3.dot w position))
        nu (- (vec3.dot u position))
        nv (- (vec3.dot v position))]
    [(. u 1) (. u 2) (. u 3) nu
     (. v 1) (. v 2) (. v 3) nv
     (. w 1) (. w 2) (. w 3) nw
     0 0 0 1]
    ))

(fn mat4.view-target [position target up]
  (mat4.view-direction position (vec3.subtract target position) up))

(fn mat4.set-view-xyz [position rotation])

(fn mat4.debug [m]
  (print "Matrix: 4x4")
  (var str "  [ ")
  (each [ key value (ipairs m) ]
    (set str (.. str value))
    (if (and (= 0 (% key 4)) (not (= 0 (% key 16))))
        (set str (.. str "\n    "))
        (set str (.. str " ")))
    )
  (set str (.. str "]"))
  (print str)
  )

mat4
