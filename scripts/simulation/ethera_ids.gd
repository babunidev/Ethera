extends RefCounted
class_name EtheraIds

const TRAIT_GRIMNIR := "trait.grimnir"
const TRAIT_WEAPON_SHAPING := "trait.weapon_shaping"
const TRAIT_ECHO_IMPRINT := "trait.echo_imprint"
const TRAIT_ROCK := "trait.rock"
const TRAIT_SHAPEABLE := "trait.shapeable"
const TRAIT_MEMORY_FOUNTAIN := "trait.memory_fountain"
const TRAIT_ECHO := "trait.echo"
const TRAIT_WEAPON := "trait.weapon"
const TRAIT_STONE_WEAPON := "trait.stone_weapon"
const TRAIT_SHARD_HOLDER := "trait.shard_holder"

const SLOT_SMALL_WEAPON := "slot.small_weapon"

const BODY_HEAD := "body.head"
const BODY_TORSO := "body.torso"
const BODY_ARMS := "body.arms"
const BODY_LEGS := "body.legs"

const INTERACTION_SHAPE_WEAPON := "interaction.shape_weapon"
const INTERACTION_ECHO_IMPRINT := "interaction.echo_imprint"

const SKILL_SHAPE_TRACE := "skill_phase.shape_trace"
const SKILL_SHARD_FIT := "skill_phase.shard_fit"

const REACTION_NONE := "reaction.none"

const TEMPLATE_STONE_CLUB := "template.stone_club"

const ENTITY_KHAR_MORR := "entity.khar_morr"
const ENTITY_FOUNTAIN := "entity.memory_fountain"
const ENTITY_ROCK := "entity.shapeable_rock"
const ENTITY_CLUB_UMBER := "entity.club.umber"
const PLACE_VILLAGE_CENTER := "place.village_center"

const CHANGE_TRAITS := "traits"
const CHANGE_INVENTORY := "inventory"
const CHANGE_NEEDS := "needs"
const CHANGE_SHARDS := "shards"
const CHANGE_STATES := "states"
const CHANGE_INJURIES := "injuries"
const CHANGE_RELATIONSHIPS := "relationships"
const CHANGE_MANIFESTATION := "manifestation"

const CMD_TICK := "tick"
const CMD_SET_WALK_DESTINATION := "set_walk_destination"
const CMD_STOP_WALKING := "stop_walking"
const CMD_SET_FOCUS_HOLD := "set_focus_hold"
const CMD_PICKUP_ITEM := "pickup_item"
const CMD_BEGIN_INTERACTION := "begin_interaction"
const CMD_SKILL_POINTER := "skill_pointer"
const CMD_SKILL_CLICK := "skill_click"

const EVENT_LOG := "log"
const EVENT_ENTITY_TRANSFORM := "entity_transform"
const EVENT_MANIFESTATION := "manifestation"
const EVENT_EQUIPMENT := "equipment"
const EVENT_ITEM_MOVED := "item_moved"
const EVENT_SHARD_CREATED := "shard_created"
const EVENT_SHARD_REFERENCE := "shard_reference"
const EVENT_INTERACTION_STARTED := "interaction_started"
const EVENT_SKILL_STARTED := "skill_started"
const EVENT_SKILL_UPDATED := "skill_updated"
const EVENT_SKILL_ENDED := "skill_ended"

const HOVER_NONE := "none"
const HOVER_PICKUP := "pickup"
const HOVER_SWAP := "swap"
const HOVER_INTERACT := "interact"

static func is_empty_slot(value: Variant) -> bool:
	return value == null or str(value) == ""
