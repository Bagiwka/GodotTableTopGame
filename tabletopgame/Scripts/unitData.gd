extends Resource

class_name UnitData

@export var M: int = 1 #MOVEMENT
@export var T: int = 1 #TOUGHNESS
@export var SV: int = 1 #SAVE
@export var W: int = 1 #WOUNDS
@export var LD: int = 1 #LEADERSHIP
@export var OC: int = 1 #OBBJECTIVE CONTROL
@export var RANGED_WEAPONS: Array[RangedWeaponResource] #RANGED WEAPONS
@export var MELEE_WEAPONS: Array[MeleeWeaponResource] #MELEE WEAPONS
@export var SIZE: float = 13 #BASE SIZE
@export var NAME: String = "Model" #MODEL NAME
