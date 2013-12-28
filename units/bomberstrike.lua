unitDef = {
  unitname            = [[bomberstrike]],
  name                = [[Kestrel]],
  description         = [[Tactical Strike Bomber]],
  amphibious          = true,
  buildCostEnergy     = 400,
  buildCostMetal      = 400,
  builder             = false,
  buildPic            = [[bomberstrike.png]],
  buildTime           = 400,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[80 10 30]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 160,

  customParams        = {
    --description_bp = [[Bombardeiro de precis?o]],
    --description_fr = [[Bombardier de Précision]],
    --description_de = [[Präzisionsbomber]],
    --description_pl = [[Bombowiec precyzyjny]],
    helptext       = [[The Kestrel launches short-range surface attack missiles that can also hit submarines. It is the best bomber for picking off single mobile targets.]],
    --helptext_bp    = [[Shadow lança uma única bomba a cada ataque, com pouca área de efeito mas grande poder. Em matéria de custo-benefício, é eficiente contra alvos caros e imóveis, mas funciona mal contra unidades móveis principalmente devido a dificuldade de acertar um alvo móvel com uma única bomba.]],
    --helptext_fr    = [[Le Shadow largue des bombes de haute précision, parfait pour les frappes chirurgicales comme une défense antimissile ou une tourelle genante, mais peu efficace contre une armée massive.]],
    --helptext_de    = [[Der Shadow wirft eine einzige Bombe mit hohem Schaden ab. Ideal fungiert er dazu, einzelne, strategisch wichtige Gebäude wie z.B. Anti-Atom zu zerstören, um dann mit seinen Haupteinheiten einzufallen. Kleinere Einheiten werden aber nur schwelich getroffen und sollten von daher auf anderem Wege bekämpft werden.]],
    --helptext_pl    = [[Shadow zrzuca pojedyncza bombe o wysokich obrazeniach i malym obszarze wybuchu. Swietnie nadaje sie do niszczenia ciezszych celow, jednak po kazdym zrzucie musi zaladowac nowa bombe na lotnisku lub stacji dozbrajania.]],
    --modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomber]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 234,
  maxAcc              = 0.5,
  maxDamage           = 900,
  maxElevator         = 0.02,
  maxRudder           = 0.006,
  maxFuel             = 1000000,
  maxVelocity         = 7.8,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[bomberstrike.s3o]],
  script              = [[bomberstrike.lua]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {},

  side                = [[CORE]],
  sightDistance       = 660,
  turnRadius          = 80,
  workerTime          = 0,

  weapons             = {
    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,      
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SINK SUB]],
    },
  },


  weaponDefs          = {
  
    MISSILE = {
      name                    = [[Heavy Missiles]],
      areaOfEffect            = 96,
      cegTag                  = [[missiletrailgreen]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 450,
        planes  = 450,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[wep_m_dragonsfang.s3o]],
      projectiles             = 2,
      range                   = 360,
      reloadtime              = 10,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 190,
      texture2                = [[lightsmoketrail]],
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 90,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
    },
    
  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Kestrel]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[bomberstrike_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Kestrel]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ bomberstrike = unitDef })
