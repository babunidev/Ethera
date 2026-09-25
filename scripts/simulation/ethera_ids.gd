extends RefCounted
class_name EtheraIds

const TRAIT_GRIMNIR := "trait.grimnir"
const TRAIT_FEMALE := "trait.female"
const TRAIT_WEAPON_SHAPING := "trait.weapon_shaping"
const TRAIT_ECHO_IMPRINT := "trait.echo_imprint"
const TRAIT_ROCK := "trait.rock"
const TRAIT_SHAPEABLE := "trait.shapeable"
const TRAIT_MEMORY_FOUNTAIN := "trait.memory_fountain"
const TRAIT_ECHO := "trait.echo"
const TRAIT_WEAPON := "trait.weapon"
const TRAIT_STONE_WEAPON := "trait.stone_weapon"
const TRAIT_SHARD_HOLDER := "trait.shard_holder"
const TRAIT_CONTAINER := "trait.container"
const TRAIT_HERB := "trait.herb"
const TRAIT_OFFERING_PLACE := "trait.offering_place"
const TRAIT_OBJECTIVE := "trait.objective"
const TRAIT_OBJECTIVE_KHAR_MORR := "trait.objective.khar_morr"

const NEED_STONE_WEAPON := "need.stone_weapon"
const TASK_ACQUIRE_STONE_WEAPON := "task.acquire_stone_weapon"
const NODE_VILLAGE_001 := "node.village_001"

const SLOT_SMALL_WEAPON := "slot.small_weapon"
const SLOT_HERB := "slot.herb"

const BODY_HEAD := "body.head"
const BODY_TORSO := "body.torso"
const BODY_ARMS := "body.arms"
const BODY_LEGS := "body.legs"

const INTERACTION_SHAPE_WEAPON := "interaction.shape_weapon"
const INTERACTION_ECHO_IMPRINT := "interaction.echo_imprint"
const INTERACTION_MAKE_OFFERING := "interaction.make_offering"
const INTERACTION_GREET := "interaction.greet"
const INTERACTION_ECHO_ATTUNEMENT := "interaction.echo_attunement"
const INTERACTION_PICK_HERB := "interaction.pick_herb"

const SKILL_SHAPE_TRACE := "skill_phase.shape_trace"
const SKILL_SHARD_FIT := "skill_phase.shard_fit"
const SKILL_MATERIAL_SELECTION := "skill_phase.material_selection"
const SKILL_CALL_AND_RESPONSE := "skill_phase.call_and_response"

# Skill phases declare their challenge in data. The runtime dispatches on the challenge,
# never on a phase id, so a new phase of an existing kind needs no code.
const CHALLENGE_TRACE := "trace_checkpoints_then_confirm"
const CHALLENGE_ALIGN := "align_rotating_symbol"

# Authored result and selection types. An unrecognized type fails closed.
const RESULT_REMOVE_MANIFESTATION := "remove_manifestation"
const RESULT_EQUIP_SPAWNED_ITEM := "equip_spawned_item"
const RESULT_SHARE_SELECTED_SHARD := "share_selected_shard"
const RESULT_SHARE_ELIGIBLE_SHARDS := "share_eligible_shards"
const RESULT_SET_BODY_REGION := "set_body_region"
const RESULT_ADD_STATE := "add_state"
const RESULT_REMOVE_STATE := "remove_state"
const RESULT_CONSUME_EQUIPPED_ITEM := "consume_equipped_item"
const RESULT_GREET := "greet"
const RESULT_REVEAL_CONTAINER := "reveal_container"
const RESULT_GRANT_VILLAGE_TASK := "grant_village_task"

const SELECT_FIRST_ELIGIBLE_SHARD := "first_eligible_shard"

const ROLE_ACTOR := "actor"
const ROLE_TARGET := "target"

const REACTION_NONE := "reaction.none"

const TEMPLATE_STONE_CLUB := "template.stone_club"
const TEMPLATE_GRASS_LEAF := "template.grass_leaf"

const ENTITY_KHAR_MORR := "entity.khar_morr"
const ENTITY_TRAKIA_VORR := "entity.trakia_vorr"
const ENTITY_TOWN_HALL := "entity.town_hall"
const TASK_DELIVER_STONE_WEAPON := "task.deliver_stone_weapon"
const TASK_DELIVER_OFFERING_HERB := "task.deliver_offering_herb"
const ENTITY_FOUNTAIN := "entity.memory_fountain"
const ENTITY_ROCK := "entity.shapeable_rock"
const ENTITY_CLUB_UMBER := "entity.club.umber"
const ENTITY_CLUB_GREEN := "entity.club.green"
const ENTITY_CONTAINER := "entity.container"
const ENTITY_STONE_CIRCLE := "entity.stone_circle"
const PLACE_VILLAGE_CENTER := "place.village_center"
const PLACE_STONE_CIRCLE := "place.ancient_stone_circle"
const STATE_SWIFTNESS := "state.swiftness"
const STATE_SHAPED := "state.shaped"

const ACTION_PICKUP := "action.pickup"
const ACTION_DISCOVERY := "action.discovery"
const RESULT_PICKED_UP := "result.picked_up"
const RESULT_DISCOVERED := "result.discovered"

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
const CMD_OPEN_CONTAINER := "open_container"
const CMD_OBSERVE_TARGET := "observe_target"
const CMD_BEGIN_INTERACTION := "begin_interaction"
const CMD_SKILL_POINTER := "skill_pointer"
const CMD_SKILL_CLICK := "skill_click"
const CMD_SELECT_NEED := "select_need"
const CMD_ACTIVATE_TASK := "activate_task"
const CMD_TAKE_STORED := "take_stored"
const CMD_DEPOSIT_EQUIPPED := "deposit_equipped"
const CMD_RELEASE_INHABITATION := "release_inhabitation"
const CMD_INHABIT := "inhabit"

const COMMIT_PENDING := "pending"
const COMMIT_VALIDATING := "validating"
const COMMIT_COMMITTED := "committed"

const TX_PICKUP := "pickup"
const TX_SWAP := "swap"
const TX_EQUIP_SPAWNED := "equip_spawned"
const TX_DISPLACE := "displace"
const TX_CONSUME := "consume"

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
const HOVER_OPEN := "open"
const HOVER_DISCOVER := "discover"
const HOVER_INTERACT := "interact"

static func is_empty_slot(value: Variant) -> bool:
	return value == null or str(value) == ""


const KIND_CONTAINER := "container"
const KIND_GRASS := "grass"


static func is_container_kind(kind: Variant) -> bool:
	var value: String = str(kind)
	return value == KIND_CONTAINER or value == KIND_GRASS
