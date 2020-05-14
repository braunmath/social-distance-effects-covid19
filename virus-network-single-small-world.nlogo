;; this sets the possible states for the turtles
turtles-own
[
  susceptible?            ;; if true, the turtle is susceptible
  infectedsymptomatic?    ;; if true, the turtle is infectious and symptomatic
  infectedasymptomatic?   ;; if true, the turtle is infectious and asymptomatic
  resistant?              ;; if true, the turtle can't be infected
  removed?                ;; if true, the turtle has been removed from the system
  virus-onset-timer       ;; number of ticks since this turtle became infected
  pathogen-level          ;; amount of pathogens in turtle
  fatal-pathogen-level?   ;; if true, the initial pathogen level was a fatal dose
  neighbor-pathogen-level ;; amount of pathogens in neighbors of turtle
  social-distanced?       ;; if true, the turtle is not interacting with any other turtles
  node-clustering-coefficient
  distance-from-other-turtles   ;; list of distances of this node from other turtles
]

links-own
[
  rewired?                    ;; keeps track of whether the link has been rewired or not
]


globals
[
  time
  number-infected-asymptomatic
  number-infected-symptomatic
  number-infected
  number-susceptible
  number-removed
  number-resistant
  number-social-distanced
  number-resistant-or-removed
  clustering-coefficient               ;; the clustering coefficient of the network; this is the
                                       ;; average of clustering coefficients of all turtles
  average-path-length                  ;; average path length of the network
  clustering-coefficient-of-lattice    ;; the clustering coefficient of the initial lattice
  average-path-length-of-lattice       ;; average path length of the initial lattice
  infinity                             ;; a very large number.
                                       ;; used to denote distance between two turtles which
                                       ;; don't have a connected or unconnected path between them
  highlight-string                     ;; message that appears on the node properties monitor
  number-rewired                       ;; number of edges that have been rewired. used for plots.
  rewire-one?                          ;; these two variables record which button was last pushed
  rewire-all?
]


to setup ; a global procedure to fully initialize the model , used once .
  clear-all
  set infinity 999999999  ;; just an arbitrary choice for a large number
  set highlight-string ""
  setup-nodes
  setup-small-world-network
  reset ; the procedure that re-initializes the model between runs
end


;; this determines the initial setup after the small world network has been created
to reset
  clear-output
  clear-all-plots
  reset-ticks
  ask turtles
    [ become-susceptible ]
  ask n-of initial-outbreak-size turtles
    [ become-initial-infected-asymptomatic ]
  ask links [ set color white ]
  set number-infected (count turtles with [(infectedsymptomatic? or infectedasymptomatic?)])
  set number-infected-symptomatic (count turtles with [ infectedsymptomatic? ])
  set number-infected-asymptomatic (count turtles with [ infectedasymptomatic? ])
  set number-susceptible (count turtles with [ susceptible? ])
  set number-removed 0
  set number-resistant 0
  set number-resistant-or-removed 0
  set number-social-distanced 0
  set time 0
end

to setup-nodes
  set-default-shape turtles "circle"
  create-turtles number-of-nodes
  ;; arrange them in a circle in order by who number
  layout-circle (sort turtles) max-pxcor - 1
end

to setup-small-world-network
  ;; set up a variable to determine if we still have a connected network
  ;; (in most cases we will since it starts out fully connected)
  let success? false
  while [not success?] [
    ;; we need to find initial values for lattice
    wire-them
    ;;calculate average path length and clustering coefficient for the lattice
    set success? do-calculations
  ]
  ;; setting the values for the initial lattice
  set clustering-coefficient-of-lattice clustering-coefficient
  set average-path-length-of-lattice average-path-length
  set number-rewired 0
  set highlight-string ""
  rewire-all
end

to go
  if all? turtles [not (infectedsymptomatic? or infectedasymptomatic?)]
    [ stop ]
  ask turtles
    [ if susceptible?
      [ set virus-onset-timer 0 ]
    ]
  ask turtles
    [ ifelse random 100 < social-distance-chance
      [
        become-social-distanced
      ]
      [
        become-non-social-distanced
      ]
      let infected-symptomatic-neighbors (count link-neighbors with [ infectedsymptomatic? ])    ;; turn social distancing on or off
      if infected-symptomatic-neighbors >= social-distance-threshold
      [
        become-social-distanced
      ]
    ]
  ask turtles
  [ if not social-distanced?
    [ set neighbor-pathogen-level (sum [ pathogen-level ] of link-neighbors with [ not social-distanced? and (infectedsymptomatic? or infectedasymptomatic?)]) ]     ;; determine neighbor-pathogen-level
  ]
  ask turtles
  [ if susceptible? and (not social-distanced?)                                                               ;; case of susceptible and not social distanced turtles
      [ set pathogen-level (pathogen-level + ((virus-spread-chance / 100) * neighbor-pathogen-level))
        if pathogen-level >= pathogen-infection-threshold
          [
            become-infected-asymptomatic
          ]
      ]
  ]
  ask turtles
  [ if infectedasymptomatic?                                                                                  ;; case of infected asymptomatic turtles
      [ if virus-onset-timer = initial-asymptomatic-period + asymptomatic-infection-period
        [
          become-resistant
        ]
        if virus-onset-timer = initial-asymptomatic-period
        [ ifelse pathogen-level >= pathogen-fatal-threshold
          [
            become-infected-symptomatic
            set fatal-pathogen-level? true
          ]
          [
            set fatal-pathogen-level? false
            if random 100 < chance-symptomatic
            [
              become-infected-symptomatic
            ]
          ]
        ]
      ]
  ]
  ask turtles
  [ if infectedsymptomatic?                                                                                  ;; case of infected asymptomatic turtles
    [ if virus-onset-timer = (initial-asymptomatic-period + symptomatic-infection-period)
      [ ifelse fatal-pathogen-level?
        [
          become-removed
        ]
        [ ifelse ( (random 100) < chance-removal )
          [
            become-removed
          ]
          [
            become-resistant
          ]
        ]
      ]
    ]
  ]
  ask turtles
    [ if virus-onset-timer > 0
      [ set virus-onset-timer (virus-onset-timer + 1) ]
    ]
  set number-infected (count turtles with [(infectedsymptomatic? or infectedasymptomatic?)])
  set number-infected-symptomatic (count turtles with [ infectedsymptomatic? ])
  set number-infected-asymptomatic (count turtles with [ infectedasymptomatic? ])
  set number-susceptible (count turtles with [ susceptible? ])
  set number-removed (count turtles with [ removed? ])
  set number-resistant (count turtles with [ resistant?])
  set number-social-distanced (count turtles with [ social-distanced?])
  set number-resistant-or-removed (number-removed + number-resistant)
  tick
  set time (time + 1)
  ;; export-view (word ticks ".png")
end

to become-initial-infected-asymptomatic
  set susceptible? false
  set infectedasymptomatic? true
  set infectedsymptomatic? false
  set resistant? false
  set removed? false
  set virus-onset-timer 1
  set pathogen-level 35 ;; the following code generates random values (pathogen-infection-threshold + (random (100 - pathogen-infection-threshold)))
  set color pink
end

to become-infected-asymptomatic  ;; turtle procedure
  set susceptible? false
  set infectedasymptomatic? true
  set infectedsymptomatic? false
  set resistant? false
  set removed? false
  set virus-onset-timer 1
  set color pink
end

to become-infected-symptomatic  ;; turtle procedure
  set susceptible? false
  set infectedasymptomatic? false
  set infectedsymptomatic? true
  set resistant? false
  set removed? false
  set color red
end

to become-susceptible  ;; turtle procedure
  set susceptible? true
  set infectedasymptomatic? false
  set infectedsymptomatic? false
  set resistant? false
  set removed? false
  set social-distanced? false
  set pathogen-level 0
  set fatal-pathogen-level? false
  set virus-onset-timer 0
  set neighbor-pathogen-level 0
  set color blue
end

to become-resistant  ;; turtle procedure
  set susceptible? false
  set infectedasymptomatic? false
  set infectedsymptomatic? false
  set resistant? true
  set removed? false
  set pathogen-level 0
  set color gray
  ask my-links [ set color gray - 2 ]
end

to become-removed
  set susceptible? false
  set infectedasymptomatic? false
  set infectedsymptomatic? false
  set resistant? false
  set removed? true
  set pathogen-level 0
  set color red
  ask my-links [ set color gray - 2 ]
end

to become-social-distanced
  set social-distanced? true
end

to become-non-social-distanced
  set social-distanced? false
end


;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedure Small World ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to rewire-all

  ;; make sure num-turtles is setup correctly; if not run setup first
  if count turtles != number-of-nodes [
    setup
  ]

  ;; record which button was pushed
  set rewire-one? false
  set rewire-all? true

  ;; set up a variable to see if the network is connected
  let success? false

  ;; if we end up with a disconnected network, we keep trying, because the APL distance
  ;; isn't meaningful for a disconnected network.
  while [not success?] [
    ;; kill the old lattice, reset neighbors, and create new lattice
    ask links [ die ]
    wire-them
    set number-rewired 0

    ask links [

      ;; whether to rewire it or not?
      if (random-float 1) < rewiring-probability
      [
        ;; "a" remains the same
        let node1 end1
        ;; if "a" is not connected to everybody
        if [ count link-neighbors ] of end1 < (count turtles - 1)
        [
          ;; find a node distinct from node1 and not already a neighbor of node1
          let node2 one-of turtles with [ (self != node1) and (not link-neighbor? node1) ]
          ;; wire the new edge
          ask node1 [ create-link-with node2 [ set rewired? true ] ]

          set number-rewired number-rewired + 1  ;; counter for number of rewirings
          set rewired? true
        ]
      ]
      ;; remove the old edge
      if (rewired?)
      [
        die
      ]
    ]

    ;; check to see if the new network is connected and calculate path length and clustering
    ;; coefficient at the same time
    set success? do-calculations
  ]

  ;; do the plotting
  update-plots
end

;; do-calculations reports true if the network is connected,
;;   and reports false if the network is disconnected.
;; (In the disconnected case, the average path length does not make sense,
;;   or perhaps may be considered infinite)
to-report do-calculations

  ;; set up a variable so we can report if the network is disconnected
  let connected? true

  ;; find the path lengths in the network
  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-turtles)] of turtles

  ;; In a connected network on N nodes, we should have N(N-1) measurements of distances between pairs,
  ;; and none of those distances should be infinity.
  ;; If there were any "infinity" length paths between nodes, then the network is disconnected.
  ;; In that case, calculating the average-path-length doesn't really make sense.
  ifelse ( num-connected-pairs != (count turtles * (count turtles - 1) ))
  [
    set average-path-length infinity
    ;; report that the network is not connected
    set connected? false
  ]
  [
    set average-path-length (sum [sum distance-from-other-turtles] of turtles) / (num-connected-pairs)
  ]
  ;; find the clustering coefficient and add to the aggregate for all iterations
  find-clustering-coefficient

  ;; report whether the network is connected or not
  report connected?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clustering computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
        ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Path length computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Implements the Floyd Warshall algorithm for All Pairs Shortest Paths
;; It is a dynamic programming algorithm which builds bigger solutions
;; from the solutions of smaller subproblems using memoization that
;; is storing the results.
;; It keeps finding incrementally if there is shorter path through
;; the kth node.
;; Since it iterates over all turtles through k,
;; so at the end we get the shortest possible path for each i and j.

to find-path-lengths
  ;; reset the distance list
  ask turtles
  [
    set distance-from-other-turtles []
  ]

  let i 0
  let j 0
  let k 0
  let node1 one-of turtles
  let node2 one-of turtles
  let node-count count turtles
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 turtle i
      set node2 turtle j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [
          set distance-from-other-turtles lput 0 distance-from-other-turtles
        ]
      ]
      [
        ;; 1 from a node to it's neighbor
        ifelse [ link-neighbor? node1 ] of node2
        [
          ask node1 [
            set distance-from-other-turtles lput 1 distance-from-other-turtles
          ]
        ]
        ;; infinite to everyone else
        [
          ask node1 [
            set distance-from-other-turtles lput infinity distance-from-other-turtles
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [k < node-count]
  [
    set i 0
    while [i < node-count]
    [
      set j 0
      while [j < node-count]
      [
        ;; alternate path length through kth node
        set dummy ( (item k [distance-from-other-turtles] of turtle i) +
          (item j [distance-from-other-turtles] of turtle k))
        ;; is the alternate path shorter?
        if dummy < (item j [distance-from-other-turtles] of turtle i)
        [
          ask turtle i [
            set distance-from-other-turtles replace-item j distance-from-other-turtles dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set k k + 1
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Edge Operations ;;;
;;;;;;;;;;;;;;;;;;;;;;;

;; creates a new lattice
to wire-them
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next average-node-degree/2 neighbors
    ;; this makes a lattice with average degree of regularity
    let index 1
    while [ index < ((average-node-degree / 2) + 1)]
    [
      make-edge turtle n
                turtle ((n + index) mod count turtles)
      set index (index + 1)
    ]
  set n (n + 1)
  ]
end

;; connects the two turtles
to make-edge [node1 node2]
  ask node1 [ create-link-with node2  [
    set rewired? false
  ] ]
end



; Copyright 2020 Ben Braun.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
658
10
1521
874
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-85
85
-85
85
1
1
1
ticks
30.0

SLIDER
22
75
256
108
virus-spread-chance
virus-spread-chance
0.0
100
20.0
0.1
1
%
HORIZONTAL

BUTTON
354
21
449
61
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
464
21
559
61
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
18
594
627
830
Network Status
time
% of nodes
0.0
200.0
0.0
100.0
true
true
"" ""
PENS
"susceptible" 1.0 0 -13345367 true "" "plot (count turtles with [not (infectedsymptomatic? or infectedasymptomatic?) and not resistant?]) / (count turtles) * 100"
"infected" 1.0 0 -2674135 true "" "plot (count turtles with [ infectedsymptomatic? or infectedasymptomatic?]) / (count turtles) * 100"
"resistant" 1.0 0 -7500403 true "" "plot (count turtles with [resistant?]) / (count turtles) * 100"
"removed" 1.0 0 -955883 true "" "plot (count turtles with [removed?]) / (count turtles) * 100"
"social distanced" 1.0 0 -11085214 true "" "plot (count turtles with [social-distanced?]) / (count turtles) * 100"

SLIDER
333
171
556
204
number-of-nodes
number-of-nodes
10
2500
500.0
5
1
NIL
HORIZONTAL

SLIDER
23
33
248
66
initial-outbreak-size
initial-outbreak-size
1
number-of-nodes
5.0
1
1
NIL
HORIZONTAL

SLIDER
335
216
540
249
average-node-degree
average-node-degree
2
number-of-nodes - 1
20.0
2
1
NIL
HORIZONTAL

MONITOR
320
351
464
396
NIL
clustering-coefficient
3
1
11

MONITOR
320
404
464
449
NIL
average-path-length
3
1
11

SLIDER
338
261
544
294
rewiring-probability
rewiring-probability
0
1
0.1
0.01
1
NIL
HORIZONTAL

TEXTBOX
336
144
569
162
Watts-Strogatz Small World input
12
0.0
1

TEXTBOX
30
10
180
28
Infection Parameters
12
0.0
1

SLIDER
21
127
244
160
initial-asymptomatic-period
initial-asymptomatic-period
1
100
3.0
1
1
NIL
HORIZONTAL

MONITOR
276
471
396
516
NIL
number-infected
3
1
11

MONITOR
478
475
621
520
NIL
number-susceptible
3
1
11

MONITOR
481
406
608
451
NIL
number-resistant
3
1
11

MONITOR
483
354
609
399
NIL
number-removed
3
1
11

SLIDER
19
442
248
475
social-distance-chance
social-distance-chance
0
100
80.0
1
1
NIL
HORIZONTAL

MONITOR
23
530
197
575
NIL
number-social-distanced
3
1
11

SLIDER
22
167
246
200
symptomatic-infection-period
symptomatic-infection-period
1
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
20
209
256
242
asymptomatic-infection-period
asymptomatic-infection-period
1
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
24
284
264
317
chance-removal
chance-removal
0
100
5.0
1
1
%
HORIZONTAL

SLIDER
21
247
250
280
pathogen-infection-threshold
pathogen-infection-threshold
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
21
330
291
363
pathogen-fatal-threshold
pathogen-fatal-threshold
0
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
24
368
251
401
chance-symptomatic
chance-symptomatic
0
100
75.0
1
1
NIL
HORIZONTAL

MONITOR
204
529
400
574
NIL
number-infected-asymptomatic
3
1
11

MONITOR
413
526
622
571
NIL
number-infected-symptomatic
3
1
11

SLIDER
18
481
257
514
social-distance-threshold
social-distance-threshold
0
number-of-nodes
5.0
1
1
NIL
HORIZONTAL

MONITOR
410
473
467
518
NIL
time
3
1
11

BUTTON
383
91
453
124
NIL
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
28
421
178
439
Behavioral parameters
12
0.0
1

MONITOR
346
299
554
344
NIL
number-resistant-or-removed
3
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates virus spread on a Watts-Strogatz small world network.

## HOW TO USE IT

Set the desired parameters for the small world network and click SETUP to create the network.

Set the desired parameters for the infection and agent behaviors and click RESET to set up the model.

Select GO to run the model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Braun, B. (2020).  Social Distancing Impact on Virus Spread for Watts-Strogatz Small World Network. 

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 Benjamin Braun.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

This code includes modified versions of the following NetLogo code:

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (2005).  NetLogo Small Worlds model.  http://ccl.northwestern.edu/netlogo/models/SmallWorlds.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="primary_test" repetitions="2" runMetricsEveryStep="false">
    <setup>reset</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>time</metric>
    <metric>number-resistant</metric>
    <metric>number-removed</metric>
    <metric>number-resistant-or-removed</metric>
    <enumeratedValueSet variable="initial-asymptomatic-period">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic-infection-period">
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symptomatic-infection-period">
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virus-spread-chance">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-removal">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pathogen-infection-threshold">
      <value value="10"/>
      <value value="25"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-symptomatic">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="social-distance-chance" first="10" step="10" last="90"/>
    <enumeratedValueSet variable="pathogen-fatal-threshold">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-distance-threshold">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="secondary_test" repetitions="1" runMetricsEveryStep="false">
    <setup>reset</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>time</metric>
    <metric>number-resistant</metric>
    <metric>number-removed</metric>
    <metric>number-resistant-or-removed</metric>
    <enumeratedValueSet variable="initial-asymptomatic-period">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic-infection-period">
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symptomatic-infection-period">
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virus-spread-chance">
      <value value="1"/>
      <value value="5"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-removal">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pathogen-infection-threshold">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-symptomatic">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="social-distance-chance" first="0" step="10" last="90"/>
    <enumeratedValueSet variable="pathogen-fatal-threshold">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-distance-threshold">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="refined_analysis_test" repetitions="1" runMetricsEveryStep="false">
    <setup>reset</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>time</metric>
    <metric>number-resistant</metric>
    <metric>number-removed</metric>
    <metric>number-resistant-or-removed</metric>
    <enumeratedValueSet variable="initial-asymptomatic-period">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic-infection-period">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="symptomatic-infection-period">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="virus-spread-chance">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-removal">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pathogen-infection-threshold">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-symptomatic">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="social-distance-chance" first="60" step="1" last="80"/>
    <enumeratedValueSet variable="pathogen-fatal-threshold">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-distance-threshold">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
