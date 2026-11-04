extends Node
## Rewarded "revive" ads through AdMob. iOS only for now (the editor uses the
## plugin's mock ads so the flow can be tested on desktop).
##
## Ads are requested only when the player asks for one: nothing is preloaded,
## cached or refreshed in the background. At startup this only gathers consent
## (UMP) and initializes the SDK, which loads no ads.

enum Result { REWARDED, NOT_REWARDED, FAILED }

const REVIVE_AD_UNIT_ID := "ca-app-pub-7674772196735378/2415447671"
## Google's sample iOS rewarded unit. Debug builds use it so testing never
## serves (or clicks) live ads on the real account.
const TEST_REWARDED_AD_UNIT_ID := "ca-app-pub-3940256099942544/1712485313"
const INIT_TIMEOUT_SEC := 5.0
const LOAD_TIMEOUT_SEC := 15.0

signal initialization_finished
## Consent info has been refreshed; the privacy options entry point may have
## appeared or disappeared.
signal privacy_options_changed
signal _load_finished(ad: RewardedAd)
signal _show_finished

var _is_initialized := false
var _is_initializing := false
var _is_busy := false
var _load_request_id := 0
var _reward_earned := false
var _show_failed := false


func _ready() -> void:
	# In the editor the plugin's mock SDK is initialized lazily on the first
	# revive instead; initializing it at launch makes the editor run abort on quit.
	if OS.get_name() == "iOS":
		_gather_consent_then_initialize()


func is_supported() -> bool:
	return OS.get_name() == "iOS" or OS.has_feature("editor")


func is_busy() -> bool:
	return _is_busy


## True when Google requires a way to revisit ad consent (EEA/UK players).
func is_privacy_options_required() -> bool:
	if not Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		return false
	return (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)


func show_privacy_options() -> void:
	if not is_privacy_options_required():
		return
	UserMessagingPlatform.show_privacy_options_form(func(error: FormError) -> void:
		if error:
			push_warning("AdMob privacy options form failed: %s" % error.message)
		privacy_options_changed.emit()
	)


## Loads one rewarded ad, shows it and frees it. Awaitable.
func show_rewarded_ad() -> Result:
	if not is_supported() or _is_busy:
		return Result.FAILED
	_is_busy = true

	if not _is_initialized:
		if not _is_initializing:
			_initialize_sdk()
		get_tree().create_timer(INIT_TIMEOUT_SEC).timeout.connect(
			func() -> void: initialization_finished.emit()
		)
		await initialization_finished

	var ad: RewardedAd = await _load_rewarded_ad()
	if ad == null:
		_is_busy = false
		return Result.FAILED

	var result := await _present(ad)
	ad.destroy()
	_is_busy = false
	return result


func _gather_consent_then_initialize() -> void:
	_is_initializing = true
	# No UMP mock exists for the editor, and without the native plugin the
	# callbacks would never fire.
	if not Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		_initialize_sdk()
		return

	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(),
		_on_consent_info_updated,
		func(error: FormError) -> void:
			push_warning("AdMob consent update failed: %s" % error.message)
			_initialize_sdk()
	)


func _on_consent_info_updated() -> void:
	privacy_options_changed.emit()
	var info := UserMessagingPlatform.consent_information
	var needs_form := (
		info.get_is_consent_form_available()
		and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
	)
	if not needs_form:
		_initialize_sdk()
		return

	UserMessagingPlatform.load_consent_form(
		func(form: ConsentForm) -> void:
			form.show(func(_error: FormError) -> void: _initialize_sdk()),
		func(error: FormError) -> void:
			push_warning("AdMob consent form failed to load: %s" % error.message)
			_initialize_sdk()
	)


func _initialize_sdk() -> void:
	_is_initializing = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_is_initialized = true
		_is_initializing = false
		initialization_finished.emit()
	MobileAds.initialize(listener)


func _ad_unit_id() -> String:
	return TEST_REWARDED_AD_UNIT_ID if OS.is_debug_build() else REVIVE_AD_UNIT_ID


func _load_rewarded_ad() -> RewardedAd:
	_load_request_id += 1
	var request_id := _load_request_id

	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		if request_id != _load_request_id:
			ad.destroy() # Arrived after the timeout; nobody wants it now.
			return
		_load_request_id += 1
		_load_finished.emit(ad)
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("Rewarded ad failed to load: %s" % error.message)
		if request_id == _load_request_id:
			_load_request_id += 1
			_load_finished.emit(null)
	get_tree().create_timer(LOAD_TIMEOUT_SEC).timeout.connect(func() -> void:
		if request_id == _load_request_id:
			push_warning("Rewarded ad load timed out")
			_load_request_id += 1
			_load_finished.emit(null)
	)

	# A fresh loader per request so a late response can't reach a newer callback.
	RewardedAdLoader.new().load(_ad_unit_id(), AdRequest.new(), callback)
	var ad: RewardedAd = await _load_finished
	return ad


func _present(ad: RewardedAd) -> Result:
	_reward_earned = false
	_show_failed = false

	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_show_finished.emit()
	callbacks.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		push_warning("Rewarded ad failed to show: %s" % error.message)
		_show_failed = true
		_show_finished.emit()
	ad.full_screen_content_callback = callbacks

	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_reward_earned = true

	var master_bus := AudioServer.get_bus_index("Master")
	var was_muted := AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, true)
	ad.show(reward_listener)
	await _show_finished
	AudioServer.set_bus_mute(master_bus, was_muted)

	if _show_failed:
		return Result.FAILED
	return Result.REWARDED if _reward_earned else Result.NOT_REWARDED
