(local mat4 (require :mat4))
(local fennel (require :fennel))

(local lg love.graphics)
(fn pp [x] (print (fennel.view x)))

(local (w h) (love.window.getMode))

;; modify the vertex-format to let us pass a v4 to the shader. By default
;; z and w are 0 1
(local vertex-format
       [["VertexPosition" :float 4]
        ["VertexTexCoord" :float 2]
        ["VertexColor" :byte 4]])

;; A function that clears a canvas to a specific colour and draws a grid
;; on it in white
(fn setup-canvas [name canvas colour]
  (fn draw-grid [w h]
  (lg.setColor 1 1 1 1)
  (for [i 20 w 20]
    (lg.line i 0 i h)
    )
  (for [j 20 h 20]
    (lg.line 0 j w j)))
  (lg.push :all)
  (lg.setCanvas canvas)
  (lg.clear colour)
  (draw-grid 200 200)
  (lg.pop))

;; Define a bunch of canvases. In a real game these could be replaced
;; with loaded textures
(local wall-image (lg.newCanvas 200 200))
(local floor-image (lg.newCanvas 200 200))
(local right-image (lg.newCanvas 200 200))
(local left-image (lg.newCanvas 200 200))
(local char-image (lg.newCanvas 200 200))
(local far-clip-image (lg.newCanvas 200 200))
(local depth-image (lg.newCanvas w h {:format :depth24 :readable true}))

;; Initialize those canvases
(setup-canvas :wall wall-image [1 0 0 1])
(setup-canvas :floor floor-image [1 1 0 1])
(setup-canvas :right right-image [0 1 1 1])
(setup-canvas :left left-image [0 0 1 1])
(setup-canvas :char char-image [1 1 1 1])

;; A helper function for drawing planes on a specific axis
(local plane {})

(fn plane.xy [x y z w h]
  [[x y z 1           0 0]
   [(+ x w) y  z 1      1 0]
   [(+ x w) (+ y h)  z 1 1 1]
   [x (+ y h)  z 1     0 1]
   ])

(fn plane.xz [x y z w h]
  [[x       y z       1 0 0]
   [(+ x w) y z       1 1 0]
   [(+ x w) y (+ z h) 1 1 1]
   [x       y (+ z h) 1 0 1]
 ])


(fn plane.yz [x y z w h]
  [[x y       z       1 0 0]
   [x (+ y w) z       1 1 0]
   [x (+ y w) (+ z h) 1 1 1]
   [x  y      (+ z h) 1 0 1]
 ])

;; Create a mesh for each plane and set its texture.
(local wall-mesh (lg.newMesh vertex-format
                             (plane.xy -100 0 0 200 200) :fan :static))
(wall-mesh:setTexture wall-image)

(local char-mesh (lg.newMesh vertex-format
                             (plane.xy -20 120 50 40 80) :fan :static))
(char-mesh:setTexture char-image)

(local floor-mesh (lg.newMesh vertex-format
                             (plane.xz -100 200 0 200 200) :fan :static))
(floor-mesh:setTexture floor-image)

(local right-mesh (lg.newMesh vertex-format
                             (plane.yz 100 0  0 200 200) :fan :static))
(right-mesh:setTexture right-image)

(local left-mesh (lg.newMesh vertex-format
                             (plane.yz -100 0  0 200 200) :fan :static))
(left-mesh:setTexture left-image)

;; This mesh is used as the background, its just white
(local far-clip-mesh (lg.newMesh vertex-format
                                 (plane.xy -10000 -10000  -1000 200000 200000) :fan :static))


;; No change to the pixel (fragment) shader. I've just included this here for ease
;; of modification
(local pshader "
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    return texturecolor * color;
}
")


;; vertex shader takes the projection matrix, the view matrix and the transform matrix.
;; we can't use the transform_projection provided by love2d as it is already multiplied
;; by the ortho matrix
(local vshader  "
uniform mat4 projection;
uniform mat4 transform;
uniform mat4 view;
vec4 position(mat4 transform_projection, vec4 vertex_position)
{    
    return  projection * view * transform * vertex_position;
}
")

(local shader (lg.newShader pshader vshader))

;; Ortho matrix, default in love2d
(local ortho (mat4.ortho! (mat4.identity) 0 w h 0 -10 10))
;; Perspective matrix
(local perspective (mat4.perspective-rhzo!
                    (mat4.identity)
                    45
                    (/ 960 720)
                    1
                    1000))

(var projection perspective)

;; Variables used by the controller
(var position-x 0)
(var position-y -110)
(var position-z -280)
(var angle-x 0)
(var angle-y 0)

;; This controler could be way better
;; left right up down
;; w s to move forward and backwards
;; q e to pitch forward and backwards
;; a d to turn left and right
(fn basic-controler [dt]
  (var (l r u p) (values 0 0 0 0))
  (let [isDown love.keyboard.isDown
        sqrt math.sqrt
        l (if (isDown :left) 1 0)
        r (if (isDown :right) 1 0)
        u (if (isDown :up) 1 0)
        d (if (isDown :down) 1 0)
        w (if (isDown :w) 1 0)
        s (if (isDown :s) 1 0)
        a (if (isDown :a) 1 0)
        D (if (isDown :d) 1 0)
        e (if (isDown :e) 1 0)
        q (if (isDown :q) 1 0)
        eq (- e q)
        ad (- D a)
        ws (- w s)
        lr (- r l)
        ud (- u d)
        m (sqrt (+ (^ lr 2) (^ ud 2)))
        mp (if (= m 0) 1 m)
        u-lr (/ lr mp)
        u-ud (/ ud mp)
        speed 10
        ]
    (set position-x (+ (* speed u-lr) position-x))
    (set position-y (+ (* speed u-ud) position-y))
    (set position-z (+ (* speed ws) position-z))
    (set angle-x (+  (* math.pi (/ eq 100)) angle-x))
    (set angle-y (+  (* math.pi (/ ad 100)) angle-y))))

;; toggle on and off the perspective matrix
(var projection-perspective? true)
(fn toggle-perspective []
  (if projection-perspective?
      (do (set projection ortho)
          (love.window.setTitle :ORTHO))
      (do (set projection perspective)
          (love.window.setTitle :PERSPECTIVE)))
  (set projection-perspective? (not projection-perspective?)))

;; toggle on and off the debug info
(var debug false)
(fn toggle-debug []
  (set debug (not debug)))

(fn love.update [dt]
  (basic-controler dt))

(fn love.draw [obj]
  (lg.push :all)
  (lg.setColor 1 1 1 1)
  (local transform (mat4.model-transform [0 0 0] [1] [angle-x angle-y 0]))
  (local view-matrix (mat4.view-direction [(- position-x) (- position-y) (- position-z)]
                                          [0 0 1]
                                          [0 1 0]))
  ;; need to set a depth-image to get properly ordered planes
  (lg.setCanvas {:depth-stencil depth-image})
  ;; set the perspective shader
  (lg.setShader shader)
  ;; pass in uniforms
  (shader:send :projection projection)
  (shader:send :view view-matrix)
  (shader:send :transform transform)
  (lg.draw far-clip-mesh)
  ;; setting depth mode to less means that any fragment point with a z value greater than
  ;; the current depth value is ignored.
  (lg.setDepthMode :less true)
  (lg.draw wall-mesh)
  (lg.draw floor-mesh)
  (lg.draw right-mesh)
  (lg.draw left-mesh)
  (lg.draw char-mesh)
  (lg.setCanvas)
  (lg.setDepthMode :always true)
  (lg.pop)
  ;; Were back in the love2d ortho camera at this point and can draw things on the screen
  ;; just like any other love2d game.
  (when debug
    (lg.push :all)
    (lg.rectangle :fill 0 0 100 75)
    (lg.setColor 0 0 0 1)
    (lg.print (.. "px: "  position-x
                  "\npy:" position-y
                  "\npz:" position-z
                  "\nax:" angle-x
                  "\nay:" angle-y))
    (lg.pop)
    )
  )

(fn love.keypressed [mode key scancode repeat]
  (match key
    "1" (toggle-perspective)
    "2" (toggle-debug)
    "r" (do
          (set angle-x 0)
          (set angle-y 0)
          (set position-x 0)
          (set position-y 0)
          (set position-z 0)
          )))
