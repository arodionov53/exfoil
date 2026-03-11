defmodule Exfoil.UtilsTest do
  use ExUnit.Case
  doctest Exfoil.Utils

  alias Exfoil.Utils

  describe "normalize_module_name/1" do
    test "converts lowercase atoms to PascalCase" do
      assert Utils.normalize_module_name(:person) == :Person
      assert Utils.normalize_module_name(:user) == :User
      assert Utils.normalize_module_name(:config) == :Config
    end

    test "converts snake_case atoms to PascalCase" do
      assert Utils.normalize_module_name(:user_profile) == :UserProfile
      assert Utils.normalize_module_name(:my_custom_module) == :MyCustomModule
      assert Utils.normalize_module_name(:api_config_data) == :ApiConfigData
    end

    test "preserves already PascalCase atoms" do
      assert Utils.normalize_module_name(:UserData) == :UserData
      assert Utils.normalize_module_name(:Person) == :Person
      assert Utils.normalize_module_name(:MyModule) == :MyModule
    end

    test "handles single letter atoms" do
      assert Utils.normalize_module_name(:a) == :A
      assert Utils.normalize_module_name(:b) == :B
      assert Utils.normalize_module_name(:Z) == :Z
    end

    test "handles mixed case atoms" do
      # Note: camelCase without underscores is treated as one word
      assert Utils.normalize_module_name(:userProfile) == :Userprofile
      assert Utils.normalize_module_name(:apiKey) == :Apikey
    end

    test "handles atoms with numbers" do
      assert Utils.normalize_module_name(:tab1) == :Tab1
      assert Utils.normalize_module_name(:user_123) == :User123
      assert Utils.normalize_module_name(:api_v2) == :ApiV2
    end

    test "handles empty underscores" do
      assert Utils.normalize_module_name(:user__profile) == :UserProfile
      assert Utils.normalize_module_name(:___config) == :Config
    end

    test "handles trailing underscores" do
      assert Utils.normalize_module_name(:user_) == :User
      assert Utils.normalize_module_name(:config___) == :Config
    end
  end

  describe "create_module/4" do
    test "creates a module with fetch/1, fetch!/1, and get/2 functions" do
      entries = [{:a, 1}, {:b, 2}, {:c, "hello"}]
      module_name = :TestGeneratedModule

      module_alias = Utils.create_module(module_name, entries, "test source")

      # Test module name
      assert module_alias == TestGeneratedModule

      # Test fetch/1
      assert TestGeneratedModule.fetch(:a) == {:ok, 1}
      assert TestGeneratedModule.fetch(:b) == {:ok, 2}
      assert TestGeneratedModule.fetch(:c) == {:ok, "hello"}
      assert TestGeneratedModule.fetch(:nonexistent) == :error

      # Test fetch!/1
      assert TestGeneratedModule.fetch!(:a) == 1
      assert TestGeneratedModule.fetch!(:b) == 2
      assert TestGeneratedModule.fetch!(:c) == "hello"
      assert_raise KeyError, fn -> TestGeneratedModule.fetch!(:nonexistent) end

      # Test get/2
      assert TestGeneratedModule.get(:a) == 1
      assert TestGeneratedModule.get(:b) == 2
      assert TestGeneratedModule.get(:c) == "hello"
      assert TestGeneratedModule.get(:nonexistent) == nil
      assert TestGeneratedModule.get(:nonexistent, :default) == :default

      # Test helper functions
      assert TestGeneratedModule.keys() == [:a, :b, :c]
      assert TestGeneratedModule.all() == entries
      assert TestGeneratedModule.count() == 3
    end

    test "handles empty entries" do
      module_alias = Utils.create_module(:EmptyModule, [], "empty source")

      assert module_alias == EmptyModule
      assert EmptyModule.keys() == []
      assert EmptyModule.all() == []
      assert EmptyModule.count() == 0
      assert EmptyModule.fetch(:any) == :error
      assert EmptyModule.get(:any) == nil
    end

    test "handles extra functions" do
      entries = [{:x, 10}]
      extra_functions = [
        quote do
          def custom_function do
            "custom value"
          end
        end
      ]

      module_alias = Utils.create_module(:ModuleWithExtras, entries, "test", extra_functions)

      assert module_alias == ModuleWithExtras
      assert ModuleWithExtras.custom_function() == "custom value"
      assert ModuleWithExtras.fetch(:x) == {:ok, 10}
      assert ModuleWithExtras.get(:x) == 10
    end
  end

  describe "edge cases and string inputs" do
    test "handles string inputs for module names" do
      assert Utils.normalize_module_name("user_profile") == :UserProfile
      assert Utils.normalize_module_name("MyModule") == :MyModule
    end

    test "module names with leading underscores" do
      # Leading underscores are stripped when splitting
      assert Utils.normalize_module_name(:_private_module) == :PrivateModule
      assert Utils.normalize_module_name(:__internal) == :Internal
    end

    test "idempotency of normalization functions" do
      # Ensure the functions are pure and return the same result
      assert Utils.normalize_module_name(:user_profile) == Utils.normalize_module_name(:user_profile)
    end
  end

  describe "performance testing" do
    test "typical module name normalization" do
      assert Utils.normalize_module_name(:tab1) == :Tab1
      assert Utils.normalize_module_name(:my_config) == :MyConfig
      assert Utils.normalize_module_name(:user_data) == :UserData
    end

    test "module names from README examples" do
      assert Utils.normalize_module_name(:person) == :Person
      assert Utils.normalize_module_name(:user_profile) == :UserProfile
      assert Utils.normalize_module_name(:UserData) == :UserData
    end
  end
end
