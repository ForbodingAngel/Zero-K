-- grav

return {
  ["grav"] = {
    drag = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 .5 1 .1   0 0 0 0]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 120,
        emitvector         = [[0,1,0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 3,
        particlelife       = 8,
        particlelifespread = 3,
        particlesize       = 160,
        particlesizespread = 80,
        particlespeed      = .1,
        particlespeedspread = 0,
        pos                = [[0, 1.0, 0]],
        sizegrowth         = -16,
        sizemod            = 1,
        texture            = [[chargeparticles]],
      },
    },
    --flash = {
    --  air                = true,
    --  class              = [[CSimpleParticleSystem]],
    --  count              = 1,
    --  ground             = true,
    --  water              = true,
    --  properties = {
    --    airdrag            = 0,
    --    colormap           = [[0 0 0 .3   0 0 0 0]],
    --    directional        = false,
    --    emitrot            = 0,
    --    emitrotspread      = 180,
    --    emitvector         = [[0, 1, 0]],
    --    gravity            = [[0, 0, 0]],
    --    numparticles       = 1,
    --    particlelife       = 15,
    --    particlelifespread = 8,
    --    particlesize       = 120,
    --    particlesizespread = 60,
    --    particlespeed      = 0,
    --    particlespeedspread = 0,
    --    pos                = [[0, 0, 0]],
    --    sizegrowth         = 1,
    --    sizemod            = 1,
    --    texture            = [[burncircle]],
    --  },
    --},
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        alpha              = 1,
        color              = [[0,0,0]],
        expansionspeed     = 7,
        ttl                = 14,
      },
    },    
--	flashalt = {
--	  air                = true,
--	  class              = [[CBitmapMuzzleFlame]],
--	  count              = 1,
--	  ground             = true,
--	  water              = true,
--	  properties = {
--		colormap           = [[0 0 0 .3   0 0 0 0]],
--		dir				   = [[0 1 0]],
--		fronttexture       = [[burncircle]],
--		frontoffset		   = 0,
--		length	           = 100,
--		pos                = [[0, 0, 0]],
--		sidetexture        = [[burncircle]],
--		size	           = 100,
--		sizegrowth         = 0,
--		ttl				   = 15,
--	  },
--	},
--    groundflash = {
--      air                = true,
--      circlealpha        = 0.8,
--      circlegrowth       = 8,
--      flashalpha         = 0.8,
--      flashsize          = 140,
--      ground             = true,
--      ttl                = 17,
--      water              = true,
--      color = {
--        [1]  = 0.1,
--        [2]  = 0.1,
--        [3]  = 0.1,
--      },
--    },
  },

}

