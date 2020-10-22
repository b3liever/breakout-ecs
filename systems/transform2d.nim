import ".." / [game_types, vmath, mixins, utils, registry, storage]

proc update(game: var Game, entity: Entity, dirty: var seq[Entity]) =
   template `?=`(name, value): bool = (let name = value; name != invalidId)
   template transform: untyped = game.transform[entity.index]
   template hierarchy: untyped = game.hierarchy[entity.index]

   if HasFresh notin game.world[entity]:
      let position = transform.world.origin
      let rotation = transform.world.rotation
      let scale = transform.world.scale

      game.mixPrevious(entity, position, rotation, scale)
   else:
      dirty.add(entity)
      game.rmComponent(entity, HasFresh)

   var childId = hierarchy.head
   while childId != invalidId:
      template childHierarchy: untyped = game.hierarchy[childId.index]

      dirty.add(childId)
      childId = childHierarchy.next

   let local = compose(transform.scale, transform.rotation, transform.translation)
   if parentId ?= hierarchy.parent:
      template parentTransform: untyped = game.transform[parentId.index]
      transform.world = parentTransform.world * local
   else:
      transform.world = local

proc sysTransform2d*(game: var Game) =
   template entity: untyped = game.dirty[i]
   template hierarchy: untyped = game.hierarchy[entity.index]

   var dirty: seq[Entity]
   # Implements partial sorting
   # Corner case of |child|parent|grand-parent| seems to be rare
   for i in 0 .. game.dirty.high:
      for j in i + 1 .. game.dirty.high:
         if game.dirty[j] == hierarchy.parent:
            swap(game.dirty[i], game.dirty[j])
            break
      update(game, entity, dirty)
   game.dirty = dirty
