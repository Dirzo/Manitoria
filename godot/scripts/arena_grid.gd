class_name ArenaGrid
extends RefCounted
## One coordinate system for paving, deployment, picking and combat bounds.
## sqrt(1.30) grows area by 30%, without stretching champions or hexagons.
const AREA_SCALE = 1.30
const LINEAR_SCALE = 1.1401754251
const BOUNDS = Vector2(12.2, 7.5) * LINEAR_SCALE
const HEX_RADIUS = 1.9
const ROW_GAP = 3.2908965344 # sqrt(3) * HEX_RADIUS
const FORMATION_COLUMNS = [-11.4, -8.55, -5.7]
const FLOOR_RADII = Vector2(17.1, 11.799) * LINEAR_SCALE
static var cached_cells: Array[Vector2i] = []
static var cached_neighbors: Dictionary = {}

static func cells() -> Array[Vector2i]:
 if not cached_cells.is_empty():return cached_cells
 var out: Array[Vector2i] = []
 for q in range(-4, 5):
  for row in range(-3, 4):
   var p = center(q, row)
   if absf(p.x) <= BOUNDS.x and absf(p.y) <= BOUNDS.y: out.append(Vector2i(q, row))
 out.make_read_only();cached_cells=out
 return cached_cells

static func point(cell: Vector2i) -> Vector2:
 return center(cell.x, cell.y)

static func nearest(point_value: Vector2) -> Vector2i:
 var best = Vector2i.ZERO
 var distance = INF
 for cell in cells():
  var d = point(cell).distance_squared_to(point_value)
  if d < distance: distance = d; best = cell
 return best

static func axial(cell: Vector2i) -> Vector2i:
 return Vector2i(cell.x, cell.y - int((cell.x - posmod(cell.x, 2)) / 2))

static func distance(a: Vector2i, b: Vector2i) -> int:
 var d = axial(a) - axial(b)
 return maxi(absi(d.x), maxi(absi(d.y), absi(d.x + d.y)))

static func neighbors(cell: Vector2i) -> Array[Vector2i]:
 if cached_neighbors.has(cell):return cached_neighbors[cell]
 var out: Array[Vector2i] = []
 for candidate in cells():
  if distance(cell, candidate) == 1: out.append(candidate)
 out.make_read_only();cached_neighbors[cell]=out
 return out

static func attack_hexes(world_range: float) -> int:
 return maxi(1, ceili(world_range / ROW_GAP))

static func center(q: int, row: int) -> Vector2:
 return Vector2(q * HEX_RADIUS * 1.5, (row + 0.5 * posmod(q, 2)) * ROW_GAP)

static func formation_position(slot: int, team: int = 0) -> Vector2:
 slot = clampi(slot, 0, 14)
 var col = slot % 3
 var q = col - 4
 var point = center(q, int(slot / 3) - 2)
 if team == 1: point.x = -point.x
 return point

static func nearest_formation_slot(point: Vector2, team: int = 0) -> int:
 var best = 0
 for slot in range(1, 15):
  if point.distance_squared_to(formation_position(slot, team)) < point.distance_squared_to(formation_position(best, team)): best = slot
 return best

static func floor_centers() -> Array[Vector2]:
 var points: Array[Vector2] = []
 for q in range(-8, 9):
  for row in range(-5, 6):
   var p = center(q, row)
   # Leave a narrow stone border around complete hex tiles.
   var edge = FLOOR_RADII - Vector2(HEX_RADIUS, HEX_RADIUS)
   if pow(p.x / edge.x, 2) + pow(p.y / edge.y, 2) <= 1.0: points.append(p)
 return points
