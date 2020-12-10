import registry, heaparray, std / algorithm

type
  Storage*[T] = object
    len: int
    sparseToPacked: array[maxEntities, EntityImpl] # mapping from sparse handles to dense values
    packedToSparse: array[maxEntities, Entity]     # mapping from dense values to sparse handles
    packed: Array[T]

template initImpl(result: typed) =
  result = Storage[T](packed: initArray[T]())
  result.sparseToPacked.fill(invalidId.EntityImpl)
  result.packedToSparse.fill(invalidId)

proc initStorage*[T](): Storage[T] =
  initImpl(result)

proc contains*[T](s: Storage[T], entity: Entity): bool =
  # Returns true if the sparse is registered to a dense index.
  let packedIndex = s.sparseToPacked[entity.index]
  packedIndex != invalidId.EntityImpl and s.packedToSparse[packedIndex] == entity

proc `[]=`*[T](s: var Storage[T], entity: Entity, value: sink T) =
  ## Inserts a `(entity, value)` pair into `s`.
  if isNil(s.packed): initImpl(s)
  let entityIndex = entity.index
  var packedIndex = s.sparseToPacked[entityIndex]
  if packedIndex == invalidId.EntityImpl:
    packedIndex = s.len.EntityImpl
    s.sparseToPacked[entityIndex] = packedIndex
    s.len.inc
  s.packedToSparse[packedIndex] = entity
  s.packed[packedIndex] = value

template get(s, entity) =
  let entityIndex = entity.index
  let packedIndex = s.sparseToPacked[entityIndex]
  if packedIndex == invalidId.EntityImpl and s.packedToSparse[packedIndex] != entity:
    raise newException(KeyError, "Entity not in Storage")
  result = s.packed[packedIndex]

proc `[]`*[T](s: var Storage[T], entity: Entity): var T =
  ## Retrieves the value at `s[entity]`. The value can be modified.
  ## If `entity` is not in `s`, the `KeyError` exception is raised.
  get(s, entity)
proc `[]`*[T](s: Storage[T], entity: Entity): lent T =
  ## Retrieves the value at `s[entity]`.
  ## If `entity` is not in `s`, the `KeyError` exception is raised.
  get(s, entity)

proc delete*[T](s: var Storage[T], entity: Entity) =
  ## Deletes `entity` from sparse set `s`. Does nothing if the key does not exist.
  let entityIndex = entity.index
  let packedIndex = s.sparseToPacked[entityIndex]
  if packedIndex != invalidId.EntityImpl and s.packedToSparse[packedIndex] == entity:
    let lastIndex = s.len - 1
    let lastEntity = s.packedToSparse[lastIndex]
    s.sparseToPacked[lastEntity.index] = packedIndex
    s.sparseToPacked[entityIndex] = invalidId.EntityImpl
    s.packed[packedIndex] = move(s.packed[lastIndex])
    s.packed[lastIndex] = default(T)
    s.packedToSparse[packedIndex] = s.packedToSparse[lastIndex]
    s.packedToSparse[lastIndex] = invalidId
    s.len.dec

proc sort*[T](s: var Storage[T], cmp: proc (x, y: T): int, order = SortOrder.Ascending) =
  for i in 1 ..< s.len:
    let x = move(s.packed[i])
    let xEnt = s.packedToSparse[i]
    let xIndex = s.sparseToPacked[xEnt.index]
    var j = i - 1
    while j >= 0 and cmp(x, s.packed[j]) * order < 0:
      let jEnt = s.packedToSparse[j]
      s.sparseToPacked[s.packedToSparse[j + 1].index] = s.sparseToPacked[jEnt.index]
      s.packedToSparse[j + 1] = jEnt
      s.packed[j + 1] = move(s.packed[j])
      dec(j)
    s.sparseToPacked[s.packedToSparse[j + 1].index] = xIndex
    s.packedToSparse[j + 1] = xEnt
    s.packed[j + 1] = x

proc clear*[T](s: var Storage[T]) =
  s.sparseToPacked.fill(invalidId.EntityImpl)
  s.packedToSparse.fill(invalidId)
  s.len = 0

iterator pairs*[T](s: Storage[T]): (Entity, lent T) =
  for i in 0 ..< s.len:
    yield (s.packedToSparse[i], s.packed[i])

proc len*[T](s: Storage[T]): int = s.len
