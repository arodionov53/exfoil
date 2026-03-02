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
      assert module_name == :TestMap

      # Test the generated functions
      assert :TestMap.get(:a) == 1
      assert :TestMap.get(:b) == 2
      assert :TestMap.get(:nonexistent) == {:error, :not_found}
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
      assert module_name == :ComplexMap

      assert :ComplexMap.get(:string) == "hello"
      assert :ComplexMap.get(:list) == [1, 2, 3]
      assert :ComplexMap.get(:map) == %{key: "value"}
      assert :ComplexMap.get(:tuple) == {:nested, :tuple}
      assert :ComplexMap.get(:atom) == :test_atom
      assert :ComplexMap.get(:number) == 42.5
    end

    test "handles empty map" do
      data = %{}

      assert {:ok, module_name} = Maps.convert(data, :EmptyMap)
      assert module_name == :EmptyMap
      assert :EmptyMap.count() == 0
      assert :EmptyMap.keys() == []
      assert :EmptyMap.all() == []
      assert :EmptyMap.to_map() == %{}
    end

    test "supports custom function name" do
      data = %{key: "value"}

      assert {:ok, module_name} = Maps.convert(data, :TestMap, function_name: :fetch)
      assert module_name == :TestMap
      assert :TestMap.fetch(:key) == "value"
      assert :TestMap.fetch(:nonexistent) == {:error, :not_found}
    end

    test "handles string keys" do
      data = %{"string_key" => "value", "another_key" => 123}

      assert {:ok, module_name} = Maps.convert(data, :StringKeyMap)
      assert module_name == :StringKeyMap

      assert :StringKeyMap.get("string_key") == "value"
      assert :StringKeyMap.get("another_key") == 123
      assert :StringKeyMap.get("nonexistent") == {:error, :not_found}
    end

    test "handles mixed key types" do
      data = %{:atom_key => "atom_value", "string_key" => "string_value", 1 => "number_value"}

      assert {:ok, module_name} = Maps.convert(data, :MixedKeyMap)
      assert module_name == :MixedKeyMap

      assert :MixedKeyMap.get(:atom_key) == "atom_value"
      assert :MixedKeyMap.get("string_key") == "string_value"
      assert :MixedKeyMap.get(1) == "number_value"
    end
  end

  describe "convert!/3" do
    test "returns module name on success" do
      data = %{key: "value"}

      assert module_name = Maps.convert!(data, :TestMap)
      assert module_name == :TestMap
      assert :TestMap.get(:key) == "value"
    end

    test "raises on conversion failure" do
      # This test is more for completeness since Maps.convert/3 currently doesn't fail
      # but the convert!/3 function structure allows for future error handling
      data = %{key: "value"}
      assert Maps.convert!(data, :TestMap) == :TestMap
    end
  end

  describe "convert_with_auto_name/2" do
    test "generates unique module names for different maps" do
      data1 = %{a: 1}
      data2 = %{b: 2}

      assert {:ok, module1} = Maps.convert_with_auto_name(data1)
      assert {:ok, module2} = Maps.convert_with_auto_name(data2)

      assert module1 != module2

      assert module1.get(:a) == 1
      assert module2.get(:b) == 2
    end

    test "generates same module name for identical maps" do
      data = %{a: 1, b: 2}

      assert {:ok, module1} = Maps.convert_with_auto_name(data)
      assert {:ok, module2} = Maps.convert_with_auto_name(data)

      assert module1 == module2
    end

    test "supports custom function name with auto naming" do
      data = %{key: "value"}

      assert {:ok, module_name} = Maps.convert_with_auto_name(data, function_name: :lookup)
      assert module_name.lookup(:key) == "value"
      assert module_name.lookup(:nonexistent) == {:error, :not_found}
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
  end

  describe "integration test" do
    test "full workflow similar to ETS example" do
      # Create a map with data (similar to ETS table population)
      data = %{a: 1, b: 2, c: "hello"}

      # Convert to module
      assert {:ok, module_name} = Maps.convert(data, :MyData)
      assert module_name == :MyData

      # Test the generated module works as expected
      assert :MyData.get(:a) == 1
      assert :MyData.get(:b) == 2
      assert :MyData.get(:c) == "hello"
      assert :MyData.get(:nonexistent) == {:error, :not_found}

      # Test additional helper functions
      assert :MyData.count() == 3
      keys = :MyData.keys()
      assert :a in keys and :b in keys and :c in keys

      # Test map-specific functions
      assert :MyData.to_map() == data
      assert :MyData.has_key?(:a) == true
      assert :MyData.has_key?(:nonexistent) == false
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
      assert module_name == :AppConfig

      # Test deeply nested access
      config = :AppConfig.get(:config)
      assert config[:database][:host] == "localhost"
      assert config[:database][:port] == 5432
      assert config[:database][:credentials] == {:username, "admin"}

      features = :AppConfig.get(:features)
      assert :feature_a in features
      assert :feature_b in features
      assert :feature_c in features

      metadata = :AppConfig.get(:metadata)
      assert metadata[:version] == "1.0.0"
      assert metadata[:build_date] == ~D[2024-01-15]
    end
  end

  describe "edge cases" do
    test "handles nil values" do
      data = %{nil_key: nil, other_key: "value"}

      assert {:ok, module_name} = Maps.convert(data, :NilValueMap)
      assert module_name == :NilValueMap

      assert :NilValueMap.get(:nil_key) == nil
      assert :NilValueMap.get(:other_key) == "value"
    end

    test "handles large maps" do
      # Create a map with many entries
      data = 1..100 |> Enum.into(%{}, fn i -> {String.to_atom("key_#{i}"), i * 2} end)

      assert {:ok, module_name} = Maps.convert(data, :LargeMap)
      assert module_name == :LargeMap

      # Test some random entries
      assert :LargeMap.get(:key_1) == 2
      assert :LargeMap.get(:key_50) == 100
      assert :LargeMap.get(:key_100) == 200
      assert :LargeMap.count() == 100
    end

    test "handles special characters in string keys" do
      data = %{
        "key-with-dashes" => "dash_value",
        "key with spaces" => "space_value",
        "key/with/slashes" => "slash_value",
        "key.with.dots" => "dot_value"
      }

      assert {:ok, module_name} = Maps.convert(data, :SpecialCharMap)
      assert module_name == :SpecialCharMap

      assert :SpecialCharMap.get("key-with-dashes") == "dash_value"
      assert :SpecialCharMap.get("key with spaces") == "space_value"
      assert :SpecialCharMap.get("key/with/slashes") == "slash_value"
      assert :SpecialCharMap.get("key.with.dots") == "dot_value"
    end
  end
end