import ".." / [game_types, vmath, mixins, utils, registry, storage]

const Query = {HasTransform2d, HasHierarchy, HasDirty}

proc update(world: var World, entity: Entity) =
   template `?=`(name, value): bool = (let name = value; name != invalidId)
   template transform: untyped = world.transform[entity.index]
   template hierarchy: untyped = world.hierarchy[entity.index]

   if HasFresh notin world.signature[entity]:
      let position = transform.world.origin
      let rotation = transform.world.rotation
      let scale = transform.world.scale

      world.mixPrevious(entity, position, rotation, scale)
      world.rmComponent(entity, HasDirty)
   else:
      world.rmComponent(entity, HasFresh)

   let local = compose(transform.scale, transform.rotation, transform.translation)
   if parentId ?= hierarchy.parent:
      template parentTransform: untyped = world.transform[parentId.index]
      transform.world = parentTransform.world * local
   else:
      transform.world = local

   var childId = hierarchy.head
   while childId != invalidId:
      template childHierarchy: untyped = world.hierarchy[childId.index]

      update(world, childId)
      childId = childHierarchy.next

proc sysTransform2d*(game: var Game) =
   for entity, has in game.world.signature.pairs:
      if has * Query == Query:
         update(game.world, entity)
