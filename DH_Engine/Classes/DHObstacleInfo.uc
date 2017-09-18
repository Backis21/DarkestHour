//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DHObstacleInfo extends Info
    hidecategories(Object,Movement,Collision,Lighting,LightColor,Karma,Force,Events,Display,Advanced,Sound)
    placeable;

struct Type
{
    var()   StaticMesh              IntactStaticMesh;
    var()   array<StaticMesh>       ClearedStaticMeshes;
    var()   sound                   ClearSound;
    var()   array<class<Emitter> >  ClearEmitterClasses;
    var()   bool                    bCanBeCut;
    var()   bool                    bCanBeMantled;
    var()   bool                    bCanBeCrushed;
    var()   bool                    bCanBeDestroyedByExplosives;
    var()   bool                    bCanBeDestroyedByWeapons;
    var()   int                     ExplosionDamageThreshold;
    var()   int                     DamageThreshold;
    var()   float                   CutDuration;
};

var()   array<Type>                 Types;

var     array<DHObstacleInstance>   Obstacles;

defaultproperties
{
    Texture=Texture'DHEngine_Tex.ObstacleInfo'
    bStatic=true
}
