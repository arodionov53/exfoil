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

  describe "normalize_function_name/1" do
    test "converts uppercase starting letters to lowercase" do
      assert Utils.normalize_function_name(:Lookup) == :lookup
      assert Utils.normalize_function_name(:GetData) == :getdata
      assert Utils.normalize_function_name(:Fetch) == :fetch
    end

    test "preserves already lowercase function names" do
      assert Utils.normalize_function_name(:get) == :get
      assert Utils.normalize_function_name(:fetch) == :fetch
      assert Utils.normalize_function_name(:lookup) == :lookup
    end

    test "handles underscore prefixed names" do
      assert Utils.normalize_function_name(:_private) == :_private
      assert Utils.normalize_function_name(:_get_data) == :_get_data
    end

    test "handles underscore followed by uppercase" do
      assert Utils.normalize_function_name(:_PrivateGet) == :_privateget
      assert Utils.normalize_function_name(:_FetchData) == :_fetchdata
      assert Utils.normalize_function_name(:_LOOKUP) == :_lookup
    end

    test "handles mixed case names" do
      # Note: only names starting with uppercase are converted
      assert Utils.normalize_function_name(:getData) == :getData
      assert Utils.normalize_function_name(:fetchUserData) == :fetchUserData
      assert Utils.normalize_function_name(:parseJSON) == :parseJSON
      # These start with uppercase so they get lowercased
      assert Utils.normalize_function_name(:GetData) == :getdata
      assert Utils.normalize_function_name(:FetchUserData) == :fetchuserdata
      assert Utils.normalize_function_name(:ParseJSON) == :parsejson
    end

    test "handles all uppercase names" do
      assert Utils.normalize_function_name(:GET) == :get
      assert Utils.normalize_function_name(:FETCH) == :fetch
      assert Utils.normalize_function_name(:LOOKUP_DATA) == :lookup_data
    end

    test "preserves snake_case function names" do
      assert Utils.normalize_function_name(:get_user) == :get_user
      assert Utils.normalize_function_name(:fetch_data) == :fetch_data
      assert Utils.normalize_function_name(:lookup_value) == :lookup_value
    end

    test "handles function names with numbers" do
      assert Utils.normalize_function_name(:Get1) == :get1
      assert Utils.normalize_function_name(:fetch2) == :fetch2
      assert Utils.normalize_function_name(:lookup_3) == :lookup_3
    end

    test "handles single letter function names" do
      assert Utils.normalize_function_name(:A) == :a
      assert Utils.normalize_function_name(:a) == :a
      assert Utils.normalize_function_name(:_A) == :_a
    end

    test "handles empty string edge case" do
      # This shouldn't happen in practice, but let's test it anyway
      assert Utils.normalize_function_name(:"") == :""
    end
  end

  describe "edge cases and special scenarios" do
    test "handles string inputs for module names" do
      # The function converts to string internally, so strings should work
      assert Utils.normalize_module_name("person") == :Person
      assert Utils.normalize_module_name("user_profile") == :UserProfile
    end

    test "handles string inputs for function names" do
      assert Utils.normalize_function_name("Lookup") == :lookup
      assert Utils.normalize_function_name("get_data") == :get_data
    end

    test "module names with special prefixes" do
      assert Utils.normalize_module_name(:elixir_module) == :ElixirModule
      # Note: underscores are treated as separators, so __meta__ becomes Meta
      assert Utils.normalize_module_name(:__meta__) == :Meta
    end

    test "function names with double underscores" do
      # Double underscores at the start are preserved
      assert Utils.normalize_function_name(:__init__) == :__init__
      # But if it starts with uppercase after underscores, only first char pattern is checked
      assert Utils.normalize_function_name(:__GetData__) == :__GetData__
    end

    test "consistency between multiple calls" do
      # Ensure the functions are pure and return the same result
      assert Utils.normalize_module_name(:user_profile) == Utils.normalize_module_name(:user_profile)
      assert Utils.normalize_function_name(:GetData) == Utils.normalize_function_name(:GetData)
    end
  end

  describe "integration with actual usage patterns" do
    test "typical ETS table name normalization" do
      assert Utils.normalize_module_name(:tab1) == :Tab1
      assert Utils.normalize_module_name(:config_dets) == :ConfigDets
      assert Utils.normalize_module_name(:user_cache) == :UserCache
    end

    test "typical custom function name normalization" do
      assert Utils.normalize_function_name(:get) == :get
      assert Utils.normalize_function_name(:fetch) == :fetch
      assert Utils.normalize_function_name(:lookup) == :lookup
      assert Utils.normalize_function_name(:Lookup) == :lookup
    end

    test "module names from README examples" do
      assert Utils.normalize_module_name(:person) == :Person
      assert Utils.normalize_module_name(:user_profile) == :UserProfile
      assert Utils.normalize_module_name(:UserData) == :UserData
      assert Utils.normalize_module_name(:my_table) == :MyTable
    end

    test "function names from README examples" do
      assert Utils.normalize_function_name(:Lookup) == :lookup
      assert Utils.normalize_function_name(:GetData) == :getdata
      assert Utils.normalize_function_name(:_PrivateGet) == :_privateget
      assert Utils.normalize_function_name(:fetch) == :fetch
    end
  end
end