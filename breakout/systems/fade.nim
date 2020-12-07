import ".." / [gametypes, heaparray, utils, dsl, registry, storage]

const Query = {HasTransform2d, HasFade, HasDraw2d}

proc update(game: var Game, entity: Entity) =
   template transform: untyped = game.world.transform[entity.index]
   template fade: untyped = game.world.fade[entity.index]
   template draw: untyped = game.world.draw2d[entity.index]

   if draw.color[3] > 0:
      let step = 255.0 * fade.step
      draw.color[3] = draw.color[3] - step.uint8
      transform.scale.x -= fade.step
      transform.scale.y -= fade.step

      game.world.mixDirty(entity)

      if transform.scale.x <= 0.0:
         game.delete(entity)

proc sysFade*(game: var Game) =
   for entity, has in game.world.signature.pairs:
      if has * Query == Query:
         update(game, entity)