defmodule ExfoilTest do
  use ExUnit.Case
  doctest Exfoil

  setup do
    # Clean up any existing test tables
    [:test_tab, :tab1, :empty_tab, :complex_tab]
    |> Enum.each(fn table ->
      if :ets.info(table) != :undefined do
        :ets.delete(table)
      end
    end)

    :ok
  end

  describe "convert/2" do
    test "converts simple ETS table to module" do
      # Create and populate ETS table
      :ets.new(:test_tab, [:named_table])
      :ets.insert(:test_tab, {:a, 1})
      :ets.insert(:test_tab, {:b, 2})

      # Convert to module
      assert {:ok, module_name} = Exfoil.convert(:test_tab)
      assert module_name == TestTab

      # Test the generated functions
      assert TestTab.fetch(:a) == {:ok, 1}
      assert TestTab.fetch(:b) == {:ok, 2}
      assert TestTab.fetch(:nonexistent) == :error

      assert TestTab.get(:a) == 1
      assert TestTab.get(:b) == 2
      assert TestTab.get(:nonexistent) == nil
      assert TestTab.get(:nonexistent, :default) == :default

      # Test the bang versions
      assert TestTab.fetch!(:a) == 1
      assert TestTab.fetch!(:b) == 2
      assert_raise KeyError, fn -> TestTab.fetch!(:nonexistent) end
    end

    test "handles different data types" do
      :ets.new(:complex_tab, [:named_table])
      :ets.insert(:complex_tab, {:string, "hello"})
      :ets.insert(:complex_tab, {:list, [1, 2, 3]})
      :ets.insert(:complex_tab, {:map, %{key: "value"}})
      :ets.insert(:complex_tab, {:tuple, {:nested, :tuple}})

      assert {:ok, module_name} = Exfoil.convert(:complex_tab)
      assert module_name == ComplexTab

      assert ComplexTab.fetch(:string) == {:ok, "hello"}
      assert ComplexTab.fetch(:list) == {:ok, [1, 2, 3]}
      assert ComplexTab.fetch(:map) == {:ok, %{key: "value"}}
      assert ComplexTab.fetch(:tuple) == {:ok, {:nested, :tuple}}

      assert ComplexTab.get(:string) == "hello"
      assert ComplexTab.get(:list) == [1, 2, 3]
      assert ComplexTab.get(:map) == %{key: "value"}
      assert ComplexTab.get(:tuple) == {:nested, :tuple}

      # Test bang versions
      assert ComplexTab.fetch!(:string) == "hello"
      assert ComplexTab.fetch!(:list) == [1, 2, 3]
      assert ComplexTab.fetch!(:map) == %{key: "value"}
      assert ComplexTab.fetch!(:tuple) == {:nested, :tuple}
    end

    test "returns error for non-existent table" do
      assert {:error, :table_not_found} = Exfoil.convert(:nonexistent_table)
    end

    test "handles empty table" do
      :ets.new(:empty_tab, [:named_table])

      assert {:ok, module_name} = Exfoil.convert(:empty_tab)
      assert module_name == EmptyTab
      assert EmptyTab.count() == 0
      assert EmptyTab.keys() == []
      assert EmptyTab.all() == []
    end

    test "supports custom module name" do
      :ets.new(:test_tab, [:named_table])
      :ets.insert(:test_tab, {:key, "value"})

      assert {:ok, module_name} = Exfoil.convert(:test_tab, module_name: :CustomModule)
      assert module_name == CustomModule
      assert CustomModule.fetch(:key) == {:ok, "value"}
      assert CustomModule.fetch!(:key) == "value"
    end

    test "ignores function_name option for backward compatibility" do
      :ets.new(:test_tab, [:named_table])
      :ets.insert(:test_tab, {:key, "value"})

      # function_name option is now ignored - modules always use Map API
      assert {:ok, module_name} = Exfoil.convert(:test_tab, function_name: :lookup)
      assert module_name == TestTab

      # Always generates fetch/1, fetch!/1, and get/2
      assert TestTab.fetch(:key) == {:ok, "value"}
      assert TestTab.fetch(:nonexistent) == :error
      assert TestTab.get(:key) == "value"
      assert TestTab.get(:nonexistent) == nil

      # Test bang version
      assert TestTab.fetch!(:key) == "value"
      assert_raise KeyError, fn -> TestTab.fetch!(:nonexistent) end
    end
  end

  describe "convert!/2" do
    test "returns module name on success" do
      :ets.new(:test_tab, [:named_table])
      :ets.insert(:test_tab, {:key, "value"})

      assert module_name = Exfoil.convert!(:test_tab)
      assert module_name == TestTab
      assert TestTab.fetch(:key) == {:ok, "value"}
      assert TestTab.fetch!(:key) == "value"
      assert TestTab.get(:key) == "value"
    end

    test "raises on non-existent table" do
      assert_raise RuntimeError, ~r/Failed to convert ETS table/, fn ->
        Exfoil.convert!(:nonexistent_table)
      end
    end
  end

  describe "generated module functions" do
    setup do
      :ets.new(:test_tab, [:named_table])
      :ets.insert(:test_tab, {:a, 1})
      :ets.insert(:test_tab, {:b, 2})
      :ets.insert(:test_tab, {:c, 3})

      {:ok, module} = Exfoil.convert(:test_tab)
      {:ok, module: module}
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
  end

  describe "integration test" do
    test "full workflow as described in documentation" do
      # Create an ETS table and populate it (as in the example)
      :ets.new(:tab1, [:named_table])
      :ets.insert(:tab1, {:a, 1})
      :ets.insert(:tab1, {:b, 2})
      :ets.insert(:tab1, {:c, "hello"})

      # Convert to module
      assert {:ok, module_name} = Exfoil.convert(:tab1)
      assert module_name == Tab1

      # Test the generated module works as expected
      assert Tab1.fetch(:a) == {:ok, 1}
      assert Tab1.fetch(:b) == {:ok, 2}
      assert Tab1.fetch(:c) == {:ok, "hello"}
      assert Tab1.fetch(:nonexistent) == :error

      assert Tab1.get(:a) == 1
      assert Tab1.get(:b) == 2
      assert Tab1.get(:c) == "hello"
      assert Tab1.get(:nonexistent) == nil
      assert Tab1.get(:nonexistent, :default) == :default

      # Test bang versions
      assert Tab1.fetch!(:a) == 1
      assert Tab1.fetch!(:b) == 2
      assert Tab1.fetch!(:c) == "hello"
      assert_raise KeyError, fn -> Tab1.fetch!(:nonexistent) end

      # Test additional helper functions
      assert Tab1.count() == 3
      keys = Tab1.keys()
      assert :a in keys and :b in keys and :c in keys
    end
  end
end
