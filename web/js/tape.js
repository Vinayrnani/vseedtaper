// Seed-tape builder, extracted verbatim from web/index.html.
// Contains the flat ribbon, the ruled U fold and the whole roll/packet
// implementation, plus the _tapeDebug / _tapeFold / _tapeRoll / _windLeader
// proof hooks. Code is a pure move: no renaming, no reformatting.
//
// LOAD ORDER: this is a classic script (not a module), so its top-level
// 'var's are shared globals. It must load AFTER the first inline script in
// index.html (which creates root, the renderer/scene and the pivots) and
// BEFORE the second inline script (which mounts the tape into toggleGroups
// and positions tapeGroup).
'use strict';

  // ---------- v122 Step 6 tape: flat ribbon -> RULED 24-section U fold -> full U (procedural) ----------
  // Mirrors seed_tape_bend() / tape_u_section() / tape_frustum() in scad/plow.scad.
  // Step 6 moved the U-bend from the roller to UNDER the dropper, where the
  // SEPARATE u_former die (same hopper frame) cuts the same channel: paper and
  // die share one set of numbers (u_flat_z, u_side_h, tape_thick, paper_width)
  // by construction, at zero clearance.
  //
  // THE FOLD IS A RULED SURFACE, NOT A HULL. Each section is three 8-vertex
  // frusta - the floor plus the two side walls - whose two end cross-sections
  // are connected by six quads, which is exactly the surface the CAD
  // polyhedron() builds. A convex hull CANNOT be used here: a side wall is a
  // rigid band that TRANSLATES inward as the fold closes, so the hull of two
  // overlapping bands is FATTER than the band (it fills the space between
  // them). That exact bug took the die web from 1.49 to 1.27 and the working
  // clearance from 0.15 to ~0.35 mid-segment, so nothing here is hulled.
  var TAPE_LEN = 234;          // tape_len: ribbon -14..220 (tape_x0, tape_flat_end)
  var TAPE_CX = 103;           // static ribbon centre = tape_x0 + TAPE_LEN/2 (CAD match; the old per-rev mod scroll slid the ribbon +/-63, uncovering the spool/nip and overhanging the chassis)
  var TAPE_X0 = -14;           // tape_x0
  var TAPE_X1 = 220;           // tape_flat_end: the end of the ribbon
  var TAPE_TRANSIT_END = 126;  // plain straight transit -> plow mouth (world X, unchanged)
  var TAPE_Z = 28;             // tape_z (+15 lift already inside the CAD number). u_flat_z 9.2 is HOPPER-LOCAL and lands on the ribbon centreline: 9.2 + 19 (hopper lift) = 28.2 = 28 + tape_thick/2.
  // ---- Step 6 fold stations + section constants (from scad/params.scad) ----
  var TAPE_PAPER_W = 25.4;     // paper_width
  var TAPE_THICK = 0.4;        // tape_thick
  var U_SIDE_H = 7.5;          // u_side_h: wall height at full fold
  var U_FLAT_Z = 9.2;          // u_flat_z: U floor datum (hopper-local), the ribbon centreline
  var U_FLAT_END_X = 81;       // u_flat_end_x = former_x0: flat ribbon ends, the fold starts
  var U_FULL_X = 91;           // u_full_x = former_x1: fold complete, full-depth U
  var U_STABLE_END_X = 114;    // u_stable_end_x: U stable + self-supporting (transit start)
  var U_N_FOLD = 24;           // n_fold: ruled segments across the fold
  var U_SEG = (U_FULL_X - U_FLAT_END_X) / U_N_FOLD; // 0.4167
  // fold_x0: the CAD's fold starts U_OVL EARLIER than the flat ribbon ends, so
  // the two bite rather than abut. That bite is the only part of the 0.02 that
  // is drawn - see the fold loop below for why the per-section overshoot is not.
  var U_OVL = 0.02;            // fold_x0's bite back into the flat ribbon
  // ---- THE ROLL: the U becomes a closed packet (scad/params.scad, Step 6) ----
  // Every number below is a LITERAL PORT of the CAD, named after it, so the
  // preview cannot drift from print/plow.scad's seed_tape_bend(). The three
  // zones along world X are: 91..100 constant full U (above), 100..114 the
  // morph, 114..220 the constant closed packet.
  var ROLL_X0 = 100;           // roll_x0: the seed drop, the last moment the U is open
  var ROLL_X1 = 114;           // roll_x1: the turner mouth == u_stable_end_x
  var PACKET_BORE_D = 7.1;     // seed_bore_d: the roll's bore (7.1 = 7.9 outer - one paper)
  var PACKET_OUTER_D = 7.9;    // 2*packet_outer_r
  var PACKET_BORE_R = PACKET_BORE_D / 2;                        // packet_bore_r  3.55
  var PACKET_OUTER_R = PACKET_BORE_R + TAPE_THICK;              // packet_outer_r 3.95
  var PACKET_MEAN_R = PACKET_BORE_R + TAPE_THICK / 2;           // packet_mean_r  3.75
  var PACKET_CENTRE_Z = PACKET_OUTER_R;                         // packet_centre_z 3.95: the
                               // packet rides on the U's own floor datum, so it occupies
                               // exactly the U's 7.9 z envelope and the morph has no step
  // THE WRAP IS DERIVED, NEVER A HARDCODED 360: 25.4 of strip about the MEAN
  // radius = 6.7733 rad = 388.07 deg, i.e. 28.07 deg (1.84mm) of lap OVER ITS
  // OWN START. A bare 360 left a slit down the packet.
  var PACKET_WRAP_RAD = TAPE_PAPER_W / PACKET_MEAN_R;          // packet_wrap_rad 6.7733
  var PACKET_WRAP_DEG = PACKET_WRAP_RAD * 180 / Math.PI;        // packet_wrap_deg 388.07
  var PACKET_WRAP_OVERLAP_DEG = PACKET_WRAP_DEG - 360;         // packet_wrap_overlap_deg 28.07
  var PACKET_POLY_SEG = 48;     // packet_poly_seg: cross-section samples - 48 so the
                                // U polyline and the tube polyline are point-for-point lerp-able
  var PACKET_ROLL_STATIONS = 24;// packet_roll_stations: x-stations across the 14mm roll
  var PACKET_SEG_BITE = 0.10;   // packet_seg_bite: cross-section overlap of neighbouring
                                // boxes. Not 0.02: a barely-bent morphed wall segment then
                                // overlapped almost coplanarly and the union shed zero-area flakes
  var PACKET_X_BITE = 0.20;     // packet_x_bite: x overlap of neighbouring roll stations
  var PACKET_CAP_STAGGER = 0.001; // packet_cap_stagger: per-box x offset of the two cap
                                // planes. The 48 end-cap quads of one station overlap each
                                // other in ONE plane, which is the single boundary OpenSCAD's
                                // triangulation cannot resolve (zero-area flake -> trimesh
                                // calls the whole tape "not watertight"). Sweeping the caps by
                                // 0.001 per box (0.047 over 48) removes the coplanality. WebGL
                                // never triangulates, so the fix is INERT here - it is ported
                                // anyway so the two implementations carry the same numbers.
  // ---- THE ROLL'S OWN GRID PARAMETERS (scad/plow.scad, seed_tape_bend()) ----
  // The stations are NOT on an equal-x grid. They sit at equal FOLD PROGRESS,
  // which needs the inverse of u_shape2()'s smootherstep, and the LAST one is a
  // derived step short of the packet. Ported here so the preview cannot
  // contradict print/tape.stl.
  var ROLL_X_BITE = 0.3;         // roll_x_bite: station 0 bites BACK into zone 1, so its
                                // u is exactly 0 and its section is congruent with the
                                // full-U prism (a congruent abutment is what used to put
                                // 30 non-manifold edges at mesh x 127.9..128.4)
  var ROLL_TAIL_DU = 0.0018;     // roll_tail_du: DERIVED in the CAD from the room the
                                // six-turner actually has - a quarter of the spare
                                // clearance, divided by how far the morph moves a
                                // sample at all. The tail station is at u = 1 - this,
                                // NOT 23/24: a station 1/24 short of the packet leaves
                                // (1-u)*8.75 = 0.09mm of paper in the throat (measured
                                // r 4.055 against a 4.025 limit) and being AT u=1 would
                                // make it congruent with zone 3.
  var TOLERANCE = 0.3;           // tolerance: the project's single clearance datum
  var SEED_DIA_MAX = 3.0;        // seed_dia_max: the largest seed the packet may pinch
  var PACKET_LEN_SAMPLES = 21;   // packet_len_samples: u = 0, 0.05, ... 1.0

  var U_POLY_SEG_WALL = 14;     // u_poly_seg_wall: segments down the -Y wall
  var U_POLY_SEG_FLOOR = 20;    // u_poly_seg_floor: segments along the floor
  var U_CENTRELINE_BOTTOM_W = 10.4; // u_centerline_bottom_w: the finished U's floor centreline width
  var U_WALL_CL_Y = U_CENTRELINE_BOTTOM_W / 2 - TAPE_THICK / 2; // u_wall_cl_y 5.0
  var U_FLOOR_CL_Z = TAPE_THICK / 2;             // u_floor_cl_z 0.2: the ribbon centreline
  var U_LEG_CL_LEN = U_SIDE_H;                   // u_leg_cl_len 7.5
  var U_FLOOR_CL_LEN = U_CENTRELINE_BOTTOM_W - TAPE_THICK; // u_floor_cl_len 10.0
  var TURNER_EXIT_CLEAR_R = 4.30;// turner_exit_clear_r: the Ø8.6 exit the packet must pass
  // THE TAPE IS OPAQUE, and it has to be. The paper is built the way the CAD
  // builds it - a chain of MANY overlapping convex solids (95 flat shingles,
  // 75 fold frusta, 25 x 48 roll boxes, 48 packet boxes) - because the CAD has to
  // UNION them and a coplanar abutment would split the mesh. A viewer DRAWS that
  // same chain, it does not union it, so every internal face of the union is
  // still in the buffer. Drawn translucent, all of them are visible: the 0.1mm
  // shingle end-caps read as heavy banding across the flat run, and the roll's
  // 48 overlapping end-cap quads read as broad dark planes in the fold. They are
  // not degenerate faces - they are real faces pointing away from every light.
  // Opaque + depth-tested, the depth buffer discards every one of them, which is
  // the whole fix; there is no hull and no convex-hull-style hack involved.
  var tapeMat = new THREE.MeshStandardMaterial({
    color: 0x3fd97c,
    roughness: 0.45, metalness: 0.0,
    emissive: 0x0d3a20, emissiveIntensity: 0.25
  });

  // u_shape(X): fold progress 0 -> 1 across former_x0..former_x1 (81..91).
  // Smootherstep, exactly as params.scad defines it, so the paper and the die
  // are at the same progress at the same world X.
  function uShape(x) {
    if (x <= U_FLAT_END_X) return 0;
    if (x >= U_FULL_X) return 1;
    var s = (x - U_FLAT_END_X) / (U_FULL_X - U_FLAT_END_X);
    return s * s * s * (s * (s * 6 - 15) + 10); // smootherstep 6s^5-15s^4+10s^3
  }
  function tapeU_w(u) { return TAPE_PAPER_W / 2 - U_SIDE_H * u; }                // 12.7 -> 5.2
  function tapeU_h(u) { return Math.max(U_SIDE_H * u + TAPE_THICK, TAPE_THICK); } // 0.4 -> 7.9

  // u_shape2(X): ROLL progress 0 -> 1 across roll_x0..roll_x1 (100..114), the
  // same smootherstep as u_shape() so the two ramps have the same wall-slope
  // character. 0 = open full U (seeds still dropping in), 1 = closed packet.
  function uShape2(x) {
    if (x <= ROLL_X0) return 0;
    if (x >= ROLL_X1) return 1;
    var s = (x - ROLL_X0) / (ROLL_X1 - ROLL_X0);
    return s * s * s * (s * (s * 6 - 15) + 10); // smootherstep 6s^5-15s^4+10s^3
  }

  // The roll is a MORPH of the U section, not a spiral: the strip's centreline
  // is sampled as two polylines with the SAME 49 points, and the morph point is
  // the straight lerp between them. Sample i runs 0..packet_poly_seg, and each
  // point is CAD (y = across the tape, z = up) in the ribbon frame.
  // u_poly_point(i): down the -Y wall (14), along the floor (20), up the +Y wall
  // (14). The 14/20/14 split is NOT uniform arclength: it puts a sample exactly
  // on BOTH corners, so the mitre is not beveled off by half a station.
  function uPolyPoint(i) {
    if (i <= U_POLY_SEG_WALL) {
      return [-U_WALL_CL_Y, U_FLOOR_CL_Z + U_LEG_CL_LEN - i * U_LEG_CL_LEN / U_POLY_SEG_WALL];
    }
    if (i <= U_POLY_SEG_WALL + U_POLY_SEG_FLOOR) {
      return [-U_WALL_CL_Y + (i - U_POLY_SEG_WALL) * U_FLOOR_CL_LEN / U_POLY_SEG_FLOOR, U_FLOOR_CL_Z];
    }
    return [U_WALL_CL_Y, U_FLOOR_CL_Z
      + (i - U_POLY_SEG_WALL - U_POLY_SEG_FLOOR) * U_LEG_CL_LEN / U_POLY_SEG_WALL];
  }
  // packet_poly_point(i): the DERIVED wrap about packet_centre_z.
  // RADIANS, NOT DEGREES - and that is the whole conversion. The CAD's
  // packet_poly_point feeds packet_wrap_deg into OpenSCAD's cos()/sin(),
  // because this OpenSCAD build has DEGREE-mode trigonometry (cos(90) == 0).
  // Math.cos/Math.sin are radian functions, so the SAME angle is fed here as
  // packet_wrap_rad; copying the degree convention would have put the first
  // sample at ~1.1deg of arc and closed the packet as a 0.06mm sliver.
  function packetPolyPoint(i) {
    var a = i / PACKET_POLY_SEG * PACKET_WRAP_RAD;
    return [PACKET_MEAN_R * Math.cos(a), PACKET_CENTRE_Z + PACKET_MEAN_R * Math.sin(a)];
  }
  function packetMorphPoint(i, u) {
    var a = uPolyPoint(i), b = packetPolyPoint(i);
    return [a[0] + u * (b[0] - a[0]), a[1] + u * (b[1] - a[1])];
  }

  // ---- THE ROLL'S STATION GRID, a line-for-line port of seed_tape_bend() ----
  // Equal FOLD PROGRESS, not equal x. u_shape2() is a smootherstep, so its slope
  // is ZERO at both ends: on an equal-x grid the first stations sat 0.0046 of
  // the fold apart (sections 0.005mm apart), i.e. coplanar faces grazing past
  // each other - the exact boolean boundary that produced zero-area flakes and
  // 4-face edges. Placing the stations at x(smootherstep_inv(u_i)) makes EVERY
  // interface 1/24 of the fold apart and every interface a clean transverse
  // crossing instead. The two ends are pinned: station 0 is at u exactly 0 and
  // the tail station at u = 1 - roll_tail_du.
  // smootherstep_at() is u_shape2()'s own easing, written out once here so the
  // inverse and the forward function cannot disagree.
  function smootherstepAt(s) {
    return s * s * s * (s * (s * 6 - 15) + 10);
  }
  // Bisection, 20 halvings = 1e-6 in s = 1.4e-5mm in x. Identical to the CAD's
  // recursion, tail call and all.
  function smootherstepInv(u, lo, hi, n) {
    if (n <= 0) return (lo + hi) / 2;
    return smootherstepAt((lo + hi) / 2) < u
      ? smootherstepInv(u, (lo + hi) / 2, hi, n - 1)
      : smootherstepInv(u, lo, (lo + hi) / 2, n - 1);
  }
  // Equal-progress stations for i = 0..N-2, then the TAIL station at
  // 1 - roll_tail_du - the one that actually reaches the turner mouth.
  function rollStationU(i) {
    return i < PACKET_ROLL_STATIONS - 1
      ? i / PACKET_ROLL_STATIONS
      : 1 - ROLL_TAIL_DU;
  }
  function rollStationS(i) { return smootherstepInv(rollStationU(i), 0, 1, 20); }
  // Each station takes its section at its OWN START x (u_shape2 at that x), and
  // every station runs on to the NEXT station's start plus packet_x_bite, so the
  // chain overlaps by a full bite. The LAST station runs on to roll_x1 itself,
  // where u_shape2 is exactly 1.0 and the turner mouth is.
  function rollStationXa(i) {
    return i <= 0 ? ROLL_X0 - ROLL_X_BITE
                  : ROLL_X0 + (ROLL_X1 - ROLL_X0) * rollStationS(i);
  }
  function rollStationLen(i) {
    return i < PACKET_ROLL_STATIONS - 1
      ? rollStationXa(i + 1) - rollStationXa(i) + PACKET_X_BITE
      : ROLL_X1 - rollStationXa(i);
  }
  // The morph's PAPER LENGTH at fold progress u: the packet_poly_seg chords of
  // the centreline polyline, which IS the strip's length as modelled. Measured,
  // and a real ACCEPTED simplification in the CAD: a point-for-point lerp
  // between the 25.0 U centreline and the 25.38 packet wrap does not conserve arc
  // length, and no resample can - it only redistributes samples along the SAME
  // curve. The envelope and both end states stay exact; two fail-loud guards
  // stand in for the length assert that cannot be made: the strip is never
  // pinched below a seed, and it never shortens again once it starts growing.
  // Both are ported below so the viewer can be checked against the same numbers.
  function packetMorphLen(u) {
    var total = 0;
    for (var i = 0; i < PACKET_POLY_SEG; i++) {
      var a = packetMorphPoint(i, u), b = packetMorphPoint(i + 1, u);
      total += Math.sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1]));
    }
    return total;
  }
  function packetLenAt(k) { return packetMorphLen(k / (PACKET_LEN_SAMPLES - 1)); }
  var PACKET_LEN_TABLE = [];
  for (var k = 0; k < PACKET_LEN_SAMPLES; k++) PACKET_LEN_TABLE.push(packetLenAt(k));
  var PACKET_LEN_MIN = Math.min.apply(null, PACKET_LEN_TABLE);
  // The worst backward step over the second half of the roll (k >= round(21/2)).
  // <= 0 means the strip never gets shorter again on its way to the packet.
  var PACKET_LEN_TAIL_BACKSTEP = -Infinity;
  for (var kb = Math.round(PACKET_LEN_SAMPLES / 2); kb <= PACKET_LEN_SAMPLES - 2; kb++) {
    PACKET_LEN_TAIL_BACKSTEP = Math.max(PACKET_LEN_TAIL_BACKSTEP,
      PACKET_LEN_TABLE[kb] - PACKET_LEN_TABLE[kb + 1]);
  }

  // Plain flat ribbon, tape_x0 .. u_flat_end_x (25.4 wide, 0.4 thick). The
  // bottom support carries it; the hopper's u_former die folds it in place.
  // ONE slab, not the CAD's 190 shingles. The shingles overlap each other by
  // 2*epsilon only so the CAD's boolean has a volume to fuse - those overlaps are
  // interior to the union, so they cost the printed part nothing and the viewer
  // nothing either, but drawn as separate solids their end-caps are 95 visible
  // bands on the one run of paper that is supposed to look flat.
  var tapeGroup = new THREE.Group();
  var tapeMeshes = [];
  var flatRunX0 = TAPE_X0;
  // The slab runs to U_FLAT_END_X, NOT to the fold's first section: the CAD
  // starts the fold at fold_x0 = flat_end - ovl (scad/plow.scad), so the run
  // OVERLAPS the fold's first section by 0.02. A zero-overlap butt would leave
  // the two solids sharing a whole face, which is the coplanar abutment the CAD
  // never allows; the overlap reduces that to a 0.02mm hairline.
  var flatRunX1 = U_FLAT_END_X;                  // 81: overlaps the fold by U_OVL
  var flatSlab = new THREE.Mesh(
    new THREE.BoxGeometry(flatRunX1 - flatRunX0, TAPE_THICK, TAPE_PAPER_W), tapeMat);
  flatSlab.position.set((flatRunX0 + flatRunX1) / 2 - TAPE_CX, TAPE_THICK / 2, 0);
  flatSlab.castShadow = true;
  tapeGroup.add(flatSlab);
  tapeMeshes.push(flatSlab);
  root.add(tapeGroup);

  // The fold + the full U. Local frame: x = world X, y up = CAD ribbon z, z
  // across (the M map means CAD -y, and every section is symmetric in y).
  var tapeFoldGroup = new THREE.Group();
  tapeFoldGroup.position.set(0, TAPE_Z, -34);
  var tapeFoldMeshes = [];

  // ONE ruled box, the twin of the CAD tape_frustum polyhedron: the
  // cross-section is the 4-point rectangle y[ya0..yb0] x z[za0..za0+ha0] at xa
  // and y[ya1..yb1] x z[za1..za1+ha1] at xa+len, and the six quads rule between
  // them - the linear taper IS the surface, exactly. Arguments stay in CAD
  // section axes (y across, z up) so they match tape_u_section() line for line;
  // each vertex is emitted as viewer (x along, y up, z across), which is the M
  // map with the root's Y lift. Swapping two axes flips handedness, which
  // cancels the CAD polyhedron's inward winding, so the triangle order is the
  // CAD one unchanged.
  // The 8-vertex / 6-quad box topology shared by the ruled frusta and by the
  // roll's segment boxes: 4 corners at xa, 4 at xa+len, each edge traversed in
  // opposite directions by its two faces (an inconsistent polyhedron is rejected
  // by the CAD's Manifold fast path with "NotManifold"). BOX_TRIS is the same
  // thing de-indexed, so every facet keeps a flat normal.
  var BOX_QUADS = [[1, 2, 3, 0], [7, 6, 5, 4], [4, 5, 1, 0],
                   [5, 6, 2, 1], [6, 7, 3, 2], [7, 4, 0, 3]];
  // Each quad (a,b,c,d) is split into its two triangles (a,b,c),(a,c,d) - so
  // BOX_TRIS is that split, done once here for the roll's boxes, which are
  // written straight out de-indexed. tapeFrustum() splits its own kept quads
  // the same way (it cannot use this table: it draws a SUBSET of the faces).
  var BOX_TRIS = [];
  BOX_QUADS.forEach(function (quad) {
    BOX_TRIS.push(quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]);
  });
  // The section pieces below do not each draw all six quads - see tapeUSection.
// A chain of sections whose neighbouring end cross-sections are the same
// section (the fold: section i's far u IS section i+1's near u) shares its end
// quads with the neighbour, and the union the CAD prints contains neither.

  // `drop` lists the BOX_QUADS faces this piece does NOT draw, so that every
  // plane of the finished section is emitted exactly ONCE. Which quad is which
  // face, given points 0-3 at xa and 4-7 at xa+len (y = up, z = across):
  //   0 west end   1 east end   2 bottom (za)   3 the yb side (a vertical wall)
  //   4 top (za+ha)             5 the ya side (a vertical wall)
  function tapeFrustum(xa, len, ya0, yb0, za0, ha0, ya1, yb1, za1, ha1, drop) {
    // Each kept quad is expanded to its two triangles HERE, so the index count is
    // a multiple of three whatever subset of faces is drawn - setIndex() with 8
    // indices (2 quads) draws two triangles and silently loses the rest.
    var tris = [];
    BOX_QUADS.forEach(function (quad, index) {
      if (drop.indexOf(index) !== -1) return;
      tris.push(quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]);
    });
    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute([
      xa,         za0, ya0,        xa,         za0, yb0,
      xa,         za0 + ha0, yb0,  xa,         za0 + ha0, ya0,
      xa + len,   za1, ya1,        xa + len,   za1, yb1,
      xa + len,   za1 + ha1, yb1,  xa + len,   za1 + ha1, ya1
    ], 3));
    geo.setIndex(tris);
    var ruled = geo.toNonIndexed();
    geo.dispose();
    ruled.computeVertexNormals();
    var m = new THREE.Mesh(ruled, tapeMat);
    m.castShadow = true;
    return m;
  }


  // ONE U-shaped section of the PAPER, ruled from fold progress u0 at xa to u1
  // at xa+len: the floor plus the two side walls, each a convex frustum. The
  // walls translate inward as the fold closes, which is the whole reason
  // nothing here may be hulled.
  //
  // THE THREE PIECES PARTITION THE SECTION: EVERY PLANE OF THE FINISHED U IS
  // DRAWN EXACTLY ONCE. The CAD's tape_u_section() builds the floor y[-w,+w]
  // z[0,t] and the walls y[+-w-t .. +-w] z[0,h], which makes THREE pairs of
  // coincident faces per section: the floor's outer faces and the walls' outer
  // faces share the plane y = +-w over the full paper thickness, and the walls'
  // bottom faces share the plane z = 0 with the floor's bottom face. For a
  // boolean that is harmless - the union has one face there, which is why the
  // CAD can lean on it - and it is exactly what the die needs. Drawn, it is 25
  // sections x 3 coincident pairs, and the depth buffer resolves the lot as a
  // comb of z-fighting lines down both walls and along the whole length of the
  // fold. So each piece drops the faces its neighbour already draws:
  //   floor  drops its two side faces (the wall's OUTER face, y = +-w over
  //          z 0..h, covers z 0..t of them, and h >= t always)
  //   walls  drop their bottom face (the floor's bottom face, z = 0 over
  //          y [-w,+w], covers their y [w-t..w] band)
  // Nothing is lost: each dropped face lies strictly inside the piece that
  // draws that plane, so the union - the outer surface, and the shape - is
  // identical to the last bit.
  //
  // The two END quads go too. Every section in the fold run butts the next one
  // on an identical cross-section (section i's far u IS section i+1's near u),
  // so those quads are interior to the chain - absent from the STL - and
  // drawing them buys a hairline of z-fighting at each of the 24 internal
  // boundaries. The run's two real ends butt the flat slab (at 80.98) and the
  // roll's first station (at 100, congruent with the full U), so nothing is
  // left open.
  var DROP_FLOOR = [0, 1, 3, 5];   // both ends + both side faces
  var DROP_WALL = [0, 1, 2];       // both ends + the bottom face
  function tapeUSection(xa, len, u0, u1) {
    var w0 = tapeU_w(u0), w1 = tapeU_w(u1);
    var h0 = tapeU_h(u0), h1 = tapeU_h(u1);
    var t = TAPE_THICK;
    [
      tapeFrustum(xa, len, -w0, w0, 0, t, -w1, w1, 0, t, DROP_FLOOR),                   // floor
      tapeFrustum(xa, len, w0 - t, w0, 0, h0, w1 - t, w1, 0, h1, DROP_WALL),           // +Y wall
      tapeFrustum(xa, len, -w0, -(w0 - t), 0, h0, -w1, -(w1 - t), 0, h1, DROP_WALL)    // -Y wall
    ].forEach(function (m) { tapeFoldGroup.add(m); tapeFoldMeshes.push(m); });
  }

  // ---- THE ROLL: the paper's cross-section swept as small convex boxes ----
  // ONE convex box of the paper, from one segment of the centreline polyline
  // (CAD tape_poly_box): len along world X, (segment length + packet_seg_bite)
  // along the segment, tape_thick across it, centred on the segment midpoint and
  // turned to the segment angle. This is the WHOLE construction pattern of the
  // packet, and it is the same pattern the CAD uses - never a convex hull (it
  // fattened walls twice in this codebase: the hull of two overlapping bands
  // FILLS the space between them) and never an offset() of a 2D section (it
  // produced sliver shells). The BITE is what makes the run a solid chain
  // instead of a coplanar abutment: two neighbouring boxes SHARE their sample
  // point, which is INTERIOR to both, so they overlap on a volume.
  // Corners are emitted in the un-rotated cube's own order - (y-,z-),(y+,z-),
  // (y+,z+),(y-,z+) along (segment, across) - so the winding is the one
  // tapeFrustum uses, and each corner is written as viewer (x along, y up, z
  // across), the same M map. The (segment, across) frame is a proper rotation
  // of the (y, z) frame, so it cannot flip the winding.
  var rollWarned = 0;                                // one place, so a station is not spammed
  function appendPolyBox(positions, xa, len, p0, p1) {
    var dy = p1[0] - p0[0], dz = p1[1] - p0[1];
    var segLen = Math.sqrt(dy * dy + dz * dz);
    if (!(len > 0) || !(segLen > 1e-6)) {          // CAD asserts; nothing legal trips this
      if (rollWarned < 3) console.warn('[tape roll] degenerate box at x=' + xa
        + ' len=' + len + ' segLen=' + segLen + ' - skipped');
      rollWarned++;
      return;
    }
    var cy = (p0[0] + p1[0]) / 2, cz = (p0[1] + p1[1]) / 2;
    var uy = dy / segLen, uz = dz / segLen;        // along the segment
    var ny = -uz, nz = uy;                         // across it (the paper thickness)
    var hSeg = segLen / 2 + PACKET_SEG_BITE / 2;
    var hNorm = TAPE_THICK / 2;
    var corner = [[-1, -1], [1, -1], [1, 1], [-1, 1]].map(function (sign) {
      return [cy + sign[0] * hSeg * uy + sign[1] * hNorm * ny,
              cz + sign[0] * hSeg * uz + sign[1] * hNorm * nz];
    });
    var verts = [];
    [xa, xa + len].forEach(function (x) {
      corner.forEach(function (c) { verts.push(x, c[1], c[0]); });
    });
    for (var t = 0; t < BOX_TRIS.length; t++) {     // BOX_TRIS indexes verts, 3 at a time
      var v = BOX_TRIS[t] * 3;                      // verts is flat: x, y, z per corner
      positions.push(verts[v], verts[v + 1], verts[v + 2]);
    }
  }

  // The WHOLE cross-section (packet_poly_seg segments) swept over one x span at
  // roll progress u: u = 0 builds the U polyline, u = 1 the closed packet. All
  // PACKET_POLY_SEG boxes of a station share one geometry, because one mesh per
  // box would add 1152 draw calls to an animated scene; de-indexed, so the flat
  // per-facet normals are the same as on the individual boxes.
  function tapePolyStation(xa, len, u) {
    var positions = [];
    for (var i = 0; i < PACKET_POLY_SEG; i++) {
      // The CAP STAGGER sweeps each box's two end planes by i*stagger (see
      // PACKET_CAP_STAGGER): without it the 48 overlapping end-cap quads of one
      // station sit in a single plane.
      appendPolyBox(positions, xa + i * PACKET_CAP_STAGGER,
        len - 2 * i * PACKET_CAP_STAGGER,
        packetMorphPoint(i, u), packetMorphPoint(i + 1, u));
    }
    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geo.computeVertexNormals();
    var m = new THREE.Mesh(geo, tapeMat);
    m.castShadow = true;
    return m;
  }

  var rollMeshes = [];      // the 24 morph stations, world 100..114
  var packetMeshes = [];    // the constant closed packet, world 114..220

  (function () {
    // 24 exact ruled sections, u_shape()-driven - the same channel the die cuts.
    // The first one bites U_OVL back into the flat ribbon so the two never meet
    // on a coplanar face. The sections are drawn U_SEG long and ABUT, with their
    // end cross-sections shared (endsShared), rather than each one overshooting
    // its neighbour by the CAD's 0.02: the floor of every section is at exactly
    // z 0..0.4, so 25 overshooting floors put a 0.02mm coplanar strip on the
    // paper's widest face at each of the 24 boundaries and the depth buffer
    // resolves that as a comb of z-fighting lines. The CAD needs the overshoot
    // because its boolean has to fuse 25 solids; the drawn union is the same
    // surface to within 0.0002mm.
    for (var i = 0; i < U_N_FOLD; i++) {
      var xa = U_FLAT_END_X - U_OVL + U_SEG * i;
      tapeUSection(xa, U_SEG, uShape(xa), uShape(xa + U_SEG));
    }
    // ZONE 1 - the constant full U, world 91..100. The fold above ends here, and
    // the seeds drop in at world 100 with the U still OPEN, so this prism is the
    // existing tapeUSection() with its far end moved from the end of the ribbon
    // to roll_x0: the roll has to start somewhere, and the CAD starts it exactly
    // at the drop. It bites U_OVL back into the last fold section.
    tapeUSection(U_FULL_X - U_OVL, ROLL_X0 - (U_FULL_X - U_OVL), 1, 1);
    // ZONE 2 - THE ROLL, world 100..114: 24 stations on the equal-FOLD-PROGRESS
    // grid (roll_station_xa/len above, a port of seed_tape_bend()'s own
    // roll_station_xa/roll_station_len), so the stations crowd where the fold is
    // steep and spread where it is flat. Each station takes its section at its
    // OWN START x - u_shape2() there, held constant across the station, exactly
    // as tape_poly_station(xa, len, u_shape2(xa + tape_x0)) does in the CAD.
    // Station 0 therefore starts 0.3 BEFORE the drop, bites back into zone 1 and
    // is at u exactly 0, congruent with the full-U prism; the last station is the
    // tail at u = 1 - 0.0018 and finishes exactly on 114. Every station
    // overruns its neighbour by packet_x_bite, so the chain overlaps
    // volumetrically and is never a coplanar abutment.
    for (var s = 0; s < PACKET_ROLL_STATIONS; s++) {
      var sx = rollStationXa(s);
      var sl = rollStationLen(s);
      var uA = uShape2(sx);
      var uB = uShape2(sx + sl);
      if (uB < uA) {
        console.warn('[tape roll] station ' + s + ' is not monotonic in x - the roll unrolls');
      }
      var station = tapePolyStation(sx, sl, uA);
      tapeFoldGroup.add(station);
      rollMeshes.push(station);
    }
    // ZONE 3 - the constant closed packet, world 114..220: bore 7.1, outer 7.9,
    // carried by the six-turner (126..159), the twister and the bind station. The
    // section never changes, so it is ONE sweep of 48 boxes over 106mm. It starts
    // a FULL packet_x_bite early (not half): the last roll station finishes
    // exactly on 114, so this is a real 0.2mm volumetric overlap, and the two
    // sections are NOT congruent - the tail station is roll_tail_du short of the
    // packet - so the two never graze.
    var packetMesh = tapePolyStation(ROLL_X1 - PACKET_X_BITE,
      TAPE_X1 - ROLL_X1 + PACKET_X_BITE, 1);
    tapeFoldGroup.add(packetMesh);
    packetMeshes.push(packetMesh);
  })();

  // v45 WIND-UP LEADER (static): narrow strip (folded-tube width 8)
  // climbing ribbon-top (218, 28.4) -> leader endpoint (272.5, 42.5), inside
  // wound pack r8 at (274,50). Mirrors the CAD leader in seed_tape_bend(); it
  // now lands on the full-U floor (top 28.4) instead of the flat ribbon.
  // This is NOT a stray sliver: it is a real CAD feature (seed_tape_bend()'s
  // "2. v45 wind-up leader"), 8mm wide and a full paper thick, and its START
  // face sits 0.15 INSIDE the closed packet (the packet runs to x 220 and its
  // floor rides at the same datum), so the two fuse - see the attachStart hook
  // value below, which the verifier checks. What made it read as a thin
  // detached ghost in a tape-only shot was the old 55%-transparent material:
  // a 0.4mm plate seen through itself. Opaque, it reads as a strip of paper.
  var LEAD_X0 = 218, LEAD_X1 = 272.5, LEAD_Z1 = 42.5, LEAD_W = 8;
  var leadDx = LEAD_X1 - LEAD_X0, leadDz = LEAD_Z1 - (TAPE_Z + TAPE_THICK);
  var leadLen = Math.sqrt(leadDx * leadDx + leadDz * leadDz);
  var leadAng = Math.atan2(leadDz, leadDx);
  var leader = new THREE.Mesh(new THREE.BoxGeometry(leadLen + 1, TAPE_THICK, LEAD_W), tapeMat);
  leader.position.set((LEAD_X0 + LEAD_X1) / 2 + 0.25 * Math.cos(leadAng),
    TAPE_Z + TAPE_THICK + leadDz / 2 + 0.25 * Math.sin(leadAng), -34);
  leader.rotation.z = leadAng;
  leader.castShadow = true;
  root.add(leader);
  // Where the leader's own start face lands, so "it is attached, not floating"
  // is a number and not a claim. Same +0.25 along the climb as the CAD puts in.
  var leadStartX = (LEAD_X0 + LEAD_X1) / 2 + 0.25 * Math.cos(leadAng)
    - (leadLen + 1) / 2 * Math.cos(leadAng);
  var leadStartY = TAPE_Z + TAPE_THICK + leadDz / 2 + 0.25 * Math.sin(leadAng)
    - (leadLen + 1) / 2 * Math.sin(leadAng);
  window._windLeader = { x0: LEAD_X0, x1: LEAD_X1, z1: LEAD_Z1, w: LEAD_W,
    packCx: 274, packCz: 50, packR: 8, mesh: leader,
    startX: leadStartX, startY: leadStartY, thickness: TAPE_THICK, length: leadLen,
    // the packet spans x up to 220 and its floor/roof are tape_z .. tape_z+7.9,
    // so a start face at x < 220 and y inside that band is INSIDE the packet.
    attachedToPacket: leadStartX < TAPE_X1 && leadStartY > TAPE_Z
      && leadStartY < TAPE_Z + 2 * PACKET_OUTER_R,
    why: 'CAD seed_tape_bend() step 2, the v45 wind-up leader: 8mm wide, one paper '
      + 'thick, climbing from the packet at x 218 to the take-up pack at 272.5' };
  root.add(tapeFoldGroup);
  // Tape proof hooks. _tapeDebug keeps its v-era fields (verify_step4/verify_step5
  // read len/cx/x0/flatEnd) and gains the Step 6 stations; _tapeFold gains the
  // Step 6 section numbers and the ruled-surface proof.
  window._tapeDebug = { len: TAPE_LEN, cx: TAPE_CX, x0: TAPE_X0, flatEnd: 220,
    foldStartX: U_FLAT_END_X, foldEndX: U_FULL_X, stableEndX: U_STABLE_END_X,
    flatRunX0: flatRunX0, flatRunX1: flatRunX1, flatRunMeshes: tapeMeshes.length };
  window._tapeFold = {
    flatEndX: 81, fullX: 91, stableEndX: 114,
    uSideH: 7.5, uFlatZ: 9.2, tapeThick: 0.4,
    uOuterW: 10.8, uInnerW: 10.0, topCenterZ: 16.7, topOuterZ: 16.9, segments: 24,
    // what the section actually builds at u=1, so a verifier can check both
    sectionOuterW: 2 * tapeU_w(1),                    // 10.4  (12.7 - 7.5)
    sectionInnerW: 2 * (tapeU_w(1) - TAPE_THICK),    // 9.6
    sectionOuterHW: tapeU_w(1),                      // 5.2
    surface: 'ruled: 8-vertex frustum per section (floor + 2 walls), 6 quads, no convex hull',
    foldX0: U_FLAT_END_X - U_OVL, foldX1: U_FULL_X - U_OVL, foldSegLen: U_SEG,
    // overlap is the CAD's per-section overlap, which exists ONLY so the
    // boolean has a volume to fuse - it is NOT drawn. drawnOverlap 0 is the
    // load-bearing fact: the 24 sections abut exactly and share their end
    // cross-sections, so the fold is one continuous ruled channel with no
    // coplanar ledge and no coincident faces. Drawing the 0.02 overshoot put a
    // 0.02mm-wide coplanar strip on the fold's floor at every boundary, and 25
    // floor faces all at exactly tape_z + tape_thick z-fight there - a comb of
    // lines down the middle of the paper. The union the CAD prints has the same
    // outer surface to within 0.0002mm.
    overlap: U_OVL, drawnOverlap: 0,
    ribbonEndX: TAPE_X1, transitEndX: TAPE_TRANSIT_END, laneY: TAPE_Z, dropX: 100,
    // the flat run, as the ONE slab it is now drawn as (the CAD's 190 shingles
    // overlap only so its boolean has a volume to fuse; drawn, that is 95 bands)
    flatRun: { x0: flatRunX0, x1: flatRunX1, meshes: tapeMeshes.length, width: TAPE_PAPER_W },
    group: tapeFoldGroup, flat: tapeGroup, foldMeshes: tapeFoldMeshes
  };

  // THE ROLL proof hook, in the same style as _tapeFold: the CAD's own numbers
  // (scad/params.scad) next to what the viewer actually BUILT from them, so a
  // verifier can check the zones, the packet envelope and the sampling without
  // re-deriving anything.
  function sampledPacketEnv() {                 // the sampled polyline's own radii
    var lo = Infinity, hi = -Infinity;
    for (var i = 0; i <= PACKET_POLY_SEG; i++) {
      var p = packetPolyPoint(i);
      var r = Math.sqrt(p[0] * p[0] + (p[1] - PACKET_CENTRE_Z) * (p[1] - PACKET_CENTRE_Z));
      if (r < lo) lo = r;
      if (r > hi) hi = r;
    }
    return [lo, hi];
  }
  var polyEnv = sampledPacketEnv();
  // The station grid itself, as built, so a verifier can compare it with the CAD
  // station for station instead of trusting the loop.
  var rollGrid = [];
  for (var gi = 0; gi < PACKET_ROLL_STATIONS; gi++) {
    rollGrid.push({ xa: rollStationXa(gi), len: rollStationLen(gi), u: rollStationU(gi),
      uBuilt: uShape2(rollStationXa(gi)) });
  }
  window._tapeRoll = {
    // ---- the three zones along world X, exactly as seed_tape_bend() builds them
    zones: { u: [U_FULL_X, ROLL_X0], morph: [ROLL_X0, ROLL_X1], packet: [ROLL_X1, TAPE_X1] },
    uZoneX0: U_FULL_X, uZoneX1: ROLL_X0,          // 91..100, the untouched full U
    morphX0: ROLL_X0, morphX1: ROLL_X1,           // 100..114, the morph
    packetX0: ROLL_X1, packetX1: TAPE_X1,         // 114..220, the closed packet
    rollX0: ROLL_X0, rollX1: ROLL_X1,             // drop point -> turner mouth
    // ---- the packet, sized by the PAPER (25.4 of strip), not by the seed
    packetBoreD: PACKET_BORE_D,                   // 7.1
    packetOuterD: PACKET_OUTER_D,                 // 7.9
    packetBoreR: PACKET_BORE_R,                   // 3.55
    packetOuterR: PACKET_OUTER_R,                 // 3.95
    packetMeanR: PACKET_MEAN_R,                   // 3.75
    packetCentreZ: PACKET_CENTRE_Z,               // 3.95: on the U's own floor datum, so
                                                  // the morph has no vertical step
    packetWrapRad: PACKET_WRAP_RAD,               // 6.7733 = paperWidth / meanR
    packetWrapDeg: PACKET_WRAP_DEG,               // 388.07, DERIVED - never a hardcoded 360
    packetWrapOverlapDeg: PACKET_WRAP_OVERLAP_DEG,// 28.07: the lap over its own start
    packetLips: PACKET_WRAP_OVERLAP_DEG > 15,     // it is a closed roll, not a slit
    // what the SAMPLED polyline measures: the bore is the near side, the outer
    // the far side, and the paper thickness sits exactly between them
    sampledBoreD: 2 * (polyEnv[0] - TAPE_THICK / 2),
    sampledOuterD: 2 * (polyEnv[1] + TAPE_THICK / 2),
    // ---- morph resolution + the three overlap fixes
    polySeg: PACKET_POLY_SEG,                     // 48 cross-section segments
    rollStations: PACKET_ROLL_STATIONS,           // 24 x-stations over the 14mm roll
    // ---- THE GRID: equal FOLD PROGRESS, not equal x. Station 0 is pinned at
    // roll_x0 - roll_x_bite (u exactly 0, congruent with zone 1's full U), the
    // middle stations sit at roll_x0 + 14*smootherstep_inv(i/24), and the LAST is
    // the TAIL at u = 1 - roll_tail_du, ending exactly on roll_x1. Equal-x spacing
    // is NOT a fallback: it is what put the first three stations 0.0046 of the
    // fold apart, and coplanar faces grazing past each other are the one boolean
    // boundary that produced zero-area flakes and 4-face edges.
    grid: 'equal fold progress: station i at x = roll_x0 + (roll_x1-roll_x0)*smootherstep_inv(u_i), '
      + 'u_i = i/24, tail station u = 1 - roll_tail_du; each station takes its section at its OWN start x',
    rollGrid: rollGrid,
    rollXBite: ROLL_X_BITE,                       // 0.3
    rollTailDu: ROLL_TAIL_DU,                     // 0.0018
    segBite: PACKET_SEG_BITE,                     // 0.10
    xBite: PACKET_X_BITE,                         // 0.20
    capStagger: PACKET_CAP_STAGGER,               // 0.001
    // ---- the ROLL'S OWN LENGTH GUARDS (packet_len_* in scad/plow.scad). The
    // bend pattern is a real, measured and accepted simplification of the fold's
    // PATH only; these two are the fail-loud guards that stand in for the length
    // conservation that cannot be had from a point-for-point lerp.
    tolerance: TOLERANCE,                         // 0.3
    seedDiaMax: SEED_DIA_MAX,                     // 3.0
    packetLenSamples: PACKET_LEN_SAMPLES,         // 21
    packetLenTable: PACKET_LEN_TABLE,             // u = 0, 0.05, ... 1.0
    packetLenMin: PACKET_LEN_MIN,                 // 17.783 - never pinches a seed
    packetLenTailBackstep: PACKET_LEN_TAIL_BACKSTEP, // <= 0 - never shortens again
    packetCentrelineLenU0: PACKET_LEN_TABLE[0],   // 25.000 (u_centreline_len)
    // ---- the 6-turner handoff the roll has to pass
    turnerExitClearR: TURNER_EXIT_CLEAR_R,         // 4.30 (Ø8.6, turner_exit_clear_r)
    turnerExitClearD: 2 * TURNER_EXIT_CLEAR_R,    // 8.6
    exitClearanceR: TURNER_EXIT_CLEAR_R - PACKET_OUTER_R, // 0.35 nominal; the CAD
                                  // measures the real fit from the turner's axis, which
                                  // sits packet_exit_ecc 0.05 above the packet's own
    // ---- construction proof
    construction: 'roll: 48-segment centreline polyline lerped U->packet by u_shape2(x), '
      + 'one convex 8-vertex box per segment per x-station (bitten 0.10 along the section, '
      + '0.20 along x, caps staggered 0.001); no convex hull, no offset()',
    trig: 'radians: Math.cos/Math.sin take the same angle the CAD passes in DEGREES '
      + '(this OpenSCAD build has degree-mode cos/sin), fed here as packet_wrap_rad',
    uPolySegWall: U_POLY_SEG_WALL, uPolySegFloor: U_POLY_SEG_FLOOR,
    group: tapeFoldGroup, rollMeshes: rollMeshes, packetMeshes: packetMeshes
  };
  window._tapeFold.roll = window._tapeRoll;   // one pointer, so there is a single copy
