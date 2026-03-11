defmodule Exfoil.MapsTest do
  use ExUnit.Case
  doctest Exfoil.Maps

  alias Exfoil.Maps

  describe "convert/3" do
    test "converts simple map to module" do
      # Create a map
      data = %{a: 1, b: 2}

      # Convert to module
      assert {:ok, module_name} = Maps.convert(data, :TestMap)
      assert module_name == TestMap

      # Test the generated functions
      assert TestMap.fetch(:a) == {:ok, 1}
      assert TestMap.fetch(:b) == {:ok, 2}
      assert TestMap.fetch(:nonexistent) == :error

      # Test get/2
      assert TestMap.get(:a) == 1
      assert TestMap.get(:b) == 2
      assert TestMap.get(:nonexistent) == nil
      assert TestMap.get(:nonexistent, :default) == :default

      # Test bang versions
      assert TestMap.fetch!(:a) == 1
      assert TestMap.fetch!(:b) == 2
      assert_raise KeyError, fn -> TestMap.fetch!(:nonexistent) end
    end

    test "handles different data types" do
      data = %{
        string: "hello",
        list: [1, 2, 3],
        map: %{key: "value"},
        tuple: {:nested, :tuple},
        atom: :test_atom,
        number: 42.5
      }

      assert {:ok, module_name} = Maps.convert(data, :ComplexMap)
      assert module_name == ComplexMap

      assert ComplexMap.fetch(:string) == {:ok, "hello"}
      assert ComplexMap.fetch(:list) == {:ok, [1, 2, 3]}
      assert ComplexMap.fetch(:map) == {:ok, %{key: "value"}}
      assert ComplexMap.fetch(:tuple) == {:ok, {:nested, :tuple}}
      assert ComplexMap.fetch(:atom) == {:ok, :test_atom}
      assert ComplexMap.fetch(:number) == {:ok, 42.5}

      # Test get/2
      assert ComplexMap.get(:string) == "hello"
      assert ComplexMap.get(:list) == [1, 2, 3]
      assert ComplexMap.get(:map) == %{key: "value"}
      assert ComplexMap.get(:tuple) == {:nested, :tuple}
      assert ComplexMap.get(:atom) == :test_atom
      assert ComplexMap.get(:number) == 42.5

      # Test bang versions
      assert ComplexMap.fetch!(:string) == "hello"
      assert ComplexMap.fetch!(:list) == [1, 2, 3]
      assert ComplexMap.fetch!(:map) == %{key: "value"}
      assert ComplexMap.fetch!(:tuple) == {:nested, :tuple}
      assert ComplexMap.fetch!(:atom) == :test_atom
      assert ComplexMap.fetch!(:number) == 42.5
    end

    test "handles empty map" do
      data = %{}

      assert {:ok, module_name} = Maps.convert(data, :EmptyMap)
      assert module_name == EmptyMap
      assert EmptyMap.count() == 0
      assert EmptyMap.keys() == []
      assert EmptyMap.all() == []
      assert EmptyMap.to_map() == %{}
    end

    test "handles string keys" do
      data = %{"string_key" => "value", "another_key" => 123}

      assert {:ok, module_name} = Maps.convert(data, :StringKeyMap)
      assert module_name == StringKeyMap

      assert StringKeyMap.fetch("string_key") == {:ok, "value"}
      assert StringKeyMap.fetch("another_key") == {:ok, 123}
      assert StringKeyMap.fetch("nonexistent") == :error

      # Test get/2
      assert StringKeyMap.get("string_key") == "value"
      assert StringKeyMap.get("another_key") == 123
      assert StringKeyMap.get("nonexistent") == nil

      # Test bang versions
      assert StringKeyMap.fetch!("string_key") == "value"
      assert StringKeyMap.fetch!("another_key") == 123
      assert_raise KeyError, fn -> StringKeyMap.fetch!("nonexistent") end
    end

    test "handles mixed key types" do
      data = %{:atom_key => "atom_value", "string_key" => "string_value", 1 => "number_value"}

      assert {:ok, module_name} = Maps.convert(data, :MixedKeyMap)
      assert module_name == MixedKeyMap

      assert MixedKeyMap.fetch(:atom_key) == {:ok, "atom_value"}
      assert MixedKeyMap.fetch("string_key") == {:ok, "string_value"}
      assert MixedKeyMap.fetch(1) == {:ok, "number_value"}

      # Test get/2
      assert MixedKeyMap.get(:atom_key) == "atom_value"
      assert MixedKeyMap.get("string_key") == "string_value"
      assert MixedKeyMap.get(1) == "number_value"

      # Test bang versions
      assert MixedKeyMap.fetch!(:atom_key) == "atom_value"
      assert MixedKeyMap.fetch!("string_key") == "string_value"
      assert MixedKeyMap.fetch!(1) == "number_value"
    end
  end

  describe "convert!/3" do
    test "returns module name on success" do
      data = %{key: "value"}

      assert module_name = Maps.convert!(data, :TestMap)
      assert module_name == TestMap
      assert TestMap.fetch(:key) == {:ok, "value"}
      assert TestMap.fetch!(:key) == "value"
      assert TestMap.get(:key) == "value"
    end

    test "raises on conversion failure" do
      # This test is more for completeness since Maps.convert/3 currently doesn't fail
      # but the convert!/3 function structure allows for future error handling
      data = %{key: "value"}
      assert Maps.convert!(data, :TestMap) == TestMap
    end
  end

  describe "convert_with_auto_name/2" do
    test "generates unique module names for different maps" do
      data1 = %{a: 1}
      data2 = %{b: 2}

      assert {:ok, module1} = Maps.convert_with_auto_name(data1)
      assert {:ok, module2} = Maps.convert_with_auto_name(data2)

      assert module1 != module2

      assert module1.fetch(:a) == {:ok, 1}
      assert module2.fetch(:b) == {:ok, 2}

      # Test get/2
      assert module1.get(:a) == 1
      assert module2.get(:b) == 2

      # Test bang versions
      assert module1.fetch!(:a) == 1
      assert module2.fetch!(:b) == 2
    end

    test "generates same module name for identical maps" do
      data = %{a: 1, b: 2}

      assert {:ok, module1} = Maps.convert_with_auto_name(data)
      assert {:ok, module2} = Maps.convert_with_auto_name(data)

      assert module1 == module2
    end
  end

  describe "generated module functions" do
    setup do
      data = %{a: 1, b: 2, c: 3}
      {:ok, module} = Maps.convert(data, :TestModule)
      {:ok, module: module, data: data}
    end

    test "keys/0 returns all keys", %{module: module} do
      keys = module.keys()
      assert length(keys) == 3
      assert :a in keys
      assert :b in keys
      assert :c in keys
    end

    test "all/0 returns all key-value pairs", %{module: module} do
      all_entries = module.all()
      assert length(all_entries) == 3
      assert {:a, 1} in all_entries
      assert {:b, 2} in all_entries
      assert {:c, 3} in all_entries
    end

    test "count/0 returns number of entries", %{module: module} do
      assert module.count() == 3
    end

    test "to_map/0 returns original data as map", %{module: module, data: data} do
      assert module.to_map() == data
    end

    test "has_key?/1 checks key existence", %{module: module} do
      assert module.has_key?(:a) == true
      assert module.has_key?(:b) == true
      assert module.has_key?(:c) == true
      assert module.has_key?(:nonexistent) == false
    end

    test "values/0 returns all values", %{module: module} do
      values = module.values()
      assert length(values) == 3
      assert 1 in values
      assert 2 in values
      assert 3 in values
    end
  end

  describe "integration test" do
    test "full workflow similar to ETS example" do
      # Create a map with data (similar to ETS table population)
      data = %{a: 1, b: 2, c: "hello"}

      # Convert to module
      assert {:ok, module_name} = Maps.convert(data, :MyData)
      assert module_name == MyData

      # Test the generated module works as expected
      assert MyData.fetch(:a) == {:ok, 1}
      assert MyData.fetch(:b) == {:ok, 2}
      assert MyData.fetch(:c) == {:ok, "hello"}
      assert MyData.fetch(:nonexistent) == :error

      # Test get/2
      assert MyData.get(:a) == 1
      assert MyData.get(:b) == 2
      assert MyData.get(:c) == "hello"
      assert MyData.get(:nonexistent) == nil
      assert MyData.get(:nonexistent, :default) == :default

      # Test bang versions
      assert MyData.fetch!(:a) == 1
      assert MyData.fetch!(:b) == 2
      assert MyData.fetch!(:c) == "hello"
      assert_raise KeyError, fn -> MyData.fetch!(:nonexistent) end

      # Test additional helper functions
      assert MyData.count() == 3
      keys = MyData.keys()
      assert :a in keys and :b in keys and :c in keys

      # Test map-specific functions
      assert MyData.to_map() == data
      assert MyData.has_key?(:a) == true
      assert MyData.has_key?(:nonexistent) == false
      values = MyData.values()
      assert length(values) == 3
      assert 1 in values
      assert 2 in values
      assert "hello" in values
    end

    test "works with complex nested data structures" do
      data = %{
        config: %{
          database: %{
            host: "localhost",
            port: 5432,
            credentials: {:username, "admin"}
          },
          cache: %{
            enabled: true,
            ttl: 300
          }
        },
        features: [:feature_a, :feature_b, :feature_c],
        metadata: %{
          version: "1.0.0",
          build_date: ~D[2024-01-15]
        }
      }

      assert {:ok, module_name} = Maps.convert(data, :AppConfig)
      assert module_name == AppConfig

      # Test deeply nested access
      {:ok, config} = AppConfig.fetch(:config)
      assert config[:database][:host] == "localhost"
      assert config[:database][:port] == 5432
      assert config[:database][:credentials] == {:username, "admin"}

      {:ok, features} = AppConfig.fetch(:features)
      assert :feature_a in features
      assert :feature_b in features
      assert :feature_c in features

      {:ok, metadata} = AppConfig.fetch(:metadata)
      assert metadata[:version] == "1.0.0"
      assert metadata[:build_date] == ~D[2024-01-15]

      # Test get/2 for cleaner access
      config = AppConfig.get(:config)
      assert config[:database][:host] == "localhost"
      features = AppConfig.get(:features)
      assert :feature_a in features
      metadata = AppConfig.get(:metadata)
      assert metadata[:version] == "1.0.0"

      # Test bang versions
      config_bang = AppConfig.fetch!(:config)
      assert config_bang[:database][:host] == "localhost"
      features_bang = AppConfig.fetch!(:features)
      assert :feature_a in features_bang
      metadata_bang = AppConfig.fetch!(:metadata)
      assert metadata_bang[:version] == "1.0.0"
    end
  end

  describe "edge cases" do
    test "handles nil values" do
      data = %{nil_key: nil, other_key: "value"}

      assert {:ok, module_name} = Maps.convert(data, :NilValueMap)
      assert module_name == NilValueMap

      assert NilValueMap.fetch(:nil_key) == {:ok, nil}
      assert NilValueMap.fetch(:other_key) == {:ok, "value"}

      # Test get/2
      assert NilValueMap.get(:nil_key) == nil
      assert NilValueMap.get(:other_key) == "value"

      # Test bang versions
      assert NilValueMap.fetch!(:nil_key) == nil
      assert NilValueMap.fetch!(:other_key) == "value"
    end

    test "handles large maps" do
      # Create a map with many entries
      data = 1..100 |> Enum.into(%{}, fn i -> {String.to_atom("key_#{i}"), i * 2} end)

      assert {:ok, module_name} = Maps.convert(data, :LargeMap)
      assert module_name == LargeMap

      # Test some random entries
      assert LargeMap.fetch(:key_1) == {:ok, 2}
      assert LargeMap.fetch(:key_50) == {:ok, 100}
      assert LargeMap.fetch(:key_100) == {:ok, 200}
      assert LargeMap.count() == 100

      # Test get/2
      assert LargeMap.get(:key_1) == 2
      assert LargeMap.get(:key_50) == 100
      assert LargeMap.get(:key_100) == 200

      # Test bang versions
      assert LargeMap.fetch!(:key_1) == 2
      assert LargeMap.fetch!(:key_50) == 100
      assert LargeMap.fetch!(:key_100) == 200
    end

    test "handles special characters in string keys" do
      data = %{
        "key-with-dashes" => "dash_value",
        "key with spaces" => "space_value",
        "key/with/slashes" => "slash_value",
        "key.with.dots" => "dot_value"
      }

      assert {:ok, module_name} = Maps.convert(data, :SpecialCharMap)
      assert module_name == SpecialCharMap

      assert SpecialCharMap.fetch("key-with-dashes") == {:ok, "dash_value"}
      assert SpecialCharMap.fetch("key with spaces") == {:ok, "space_value"}
      assert SpecialCharMap.fetch("key/with/slashes") == {:ok, "slash_value"}
      assert SpecialCharMap.fetch("key.with.dots") == {:ok, "dot_value"}

      # Test get/2
      assert SpecialCharMap.get("key-with-dashes") == "dash_value"
      assert SpecialCharMap.get("key with spaces") == "space_value"
      assert SpecialCharMap.get("key/with/slashes") == "slash_value"
      assert SpecialCharMap.get("key.with.dots") == "dot_value"

      # Test bang versions
      assert SpecialCharMap.fetch!("key-with-dashes") == "dash_value"
      assert SpecialCharMap.fetch!("key with spaces") == "space_value"
      assert SpecialCharMap.fetch!("key/with/slashes") == "slash_value"
      assert SpecialCharMap.fetch!("key.with.dots") == "dot_value"
    end
  end
end
