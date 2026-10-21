extends GutTest

const PRESETS_PATH := "res://export_presets.cfg"
const WORKFLOW_PATH := "res://.github/workflows/build.yml"
const LINUX_PRESET := "Linux x86_64"
const WINDOWS_PRESET := "Windows x86_64"
const EXCLUDED_FOLDERS := ["addons/gut/*", "test/*", "tools/*", "docs/*"]


func _load_presets() -> ConfigFile:
	var config := ConfigFile.new()
	var error := config.load(PRESETS_PATH)
	assert_eq(error, OK, "O arquivo de presets de exportação deve ser válido")
	return config


func _find_preset(config: ConfigFile, preset_name: String) -> String:
	for section in config.get_sections():
		if not section.begins_with("preset."):
			continue
		if section.ends_with(".options"):
			continue
		if config.get_value(section, "name", "") == preset_name:
			return section
	return ""


func test_presets_file_exists() -> void:
	assert_true(FileAccess.file_exists(PRESETS_PATH), "export_presets.cfg deve existir na raiz do projeto")


func test_linux_and_windows_presets_are_declared() -> void:
	var config := _load_presets()
	var linux_section := _find_preset(config, LINUX_PRESET)
	var windows_section := _find_preset(config, WINDOWS_PRESET)
	assert_ne(linux_section, "", "O preset %s deve existir" % LINUX_PRESET)
	assert_ne(windows_section, "", "O preset %s deve existir" % WINDOWS_PRESET)
	if linux_section == "" or windows_section == "":
		return
	assert_eq(config.get_value(linux_section, "platform", ""), "Linux")
	assert_eq(config.get_value(windows_section, "platform", ""), "Windows Desktop")


func test_presets_target_x86_64_and_embed_the_pack() -> void:
	var config := _load_presets()
	for preset_name in [LINUX_PRESET, WINDOWS_PRESET]:
		var section := _find_preset(config, preset_name)
		assert_ne(section, "", "O preset %s deve existir" % preset_name)
		if section == "":
			continue
		var options := "%s.options" % section
		assert_eq(config.get_value(options, "binary_format/architecture", ""), "x86_64")
		assert_true(config.get_value(options, "binary_format/embed_pck", false))


func test_presets_exclude_test_and_addon_folders() -> void:
	var config := _load_presets()
	for preset_name in [LINUX_PRESET, WINDOWS_PRESET]:
		var section := _find_preset(config, preset_name)
		assert_ne(section, "", "O preset %s deve existir" % preset_name)
		if section == "":
			continue
		var exclude_filter: String = config.get_value(section, "exclude_filter", "")
		for folder in EXCLUDED_FOLDERS:
			assert_true(exclude_filter.contains(folder), "%s deve excluir %s do pacote" % [preset_name, folder])


func test_windows_preset_uses_the_project_icon() -> void:
	var config := _load_presets()
	var section := _find_preset(config, WINDOWS_PRESET)
	assert_ne(section, "", "O preset %s deve existir" % WINDOWS_PRESET)
	if section == "":
		return
	var options := "%s.options" % section
	var icon_path: String = config.get_value(options, "application/icon", "")
	assert_ne(icon_path, "", "O preset do Windows deve apontar para um ícone")
	if icon_path == "":
		return
	assert_true(ResourceLoader.exists(icon_path), "O ícone %s deve existir no projeto" % icon_path)
	assert_eq(ProjectSettings.get_setting("application/config/icon", ""), icon_path)


func test_project_version_is_declared() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	assert_ne(version, "", "O projeto deve declarar a versão para a exportação")
	for part in version.split("."):
		assert_true(part.is_valid_int(), "A versão deve conter apenas números: %s" % version)


func test_build_workflow_exports_both_presets() -> void:
	assert_true(FileAccess.file_exists(WORKFLOW_PATH), "O workflow de build deve existir")
	var content := FileAccess.get_file_as_string(WORKFLOW_PATH)
	assert_true(content.contains("tags: [\"v*\"]"), "O build deve começar por uma tag v*")
	assert_true(content.contains("--export-release \"%s\"" % LINUX_PRESET))
	assert_true(content.contains("--export-release \"%s\"" % WINDOWS_PRESET))
	assert_true(content.contains("config/version"), "O build deve gravar a versão da tag no projeto")
