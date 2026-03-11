defmodule EtsTableTypesTest do
  use ExUnit.Case

  describe "Exfoil with different ETS table types" do
    test "works with :set tables (default type)" do
      :ets.new(:test_set, [:named_table, :set])
      :ets.insert(:test_set, {:a, 1})
      :ets.insert(:test_set, {:b, 2})
      :ets.insert(:test_set, {:a, 3})  # Overwrites {:a, 1}

      {:ok, TestSet} = Exfoil.convert(:test_set)

      # Set tables keep only the latest value for each key
      assert TestSet.fetch(:a) == {:ok, 3}
      assert TestSet.fetch(:b) == {:ok, 2}
      assert TestSet.count() == 2
      assert length(TestSet.keys()) == 2
    end

    test "works with :ordered_set tables" do
      :ets.new(:test_ordered_set, [:named_table, :ordered_set])
      :ets.insert(:test_ordered_set, {:c, 3})
      :ets.insert(:test_ordered_set, {:a, 1})
      :ets.insert(:test_ordered_set, {:b, 2})

      {:ok, TestOrderedSet} = Exfoil.convert(:test_ordered_set)

      assert TestOrderedSet.fetch(:a) == {:ok, 1}
      assert TestOrderedSet.fetch(:b) == {:ok, 2}
      assert TestOrderedSet.fetch(:c) == {:ok, 3}

      # Ordered sets maintain key order
      assert TestOrderedSet.keys() == [:a, :b, :c]
      assert TestOrderedSet.all() == [a: 1, b: 2, c: 3]
    end

    test "works with :bag tables but only returns first value" do
      :ets.new(:test_bag, [:named_table, :bag])
      :ets.insert(:test_bag, {:a, 1})
      :ets.insert(:test_bag, {:a, 2})
      :ets.insert(:test_bag, {:b, 3})
      :ets.insert(:test_bag, {:a, 2})  # Won't create duplicate

      {:ok, TestBag} = Exfoil.convert(:test_bag)

      # Only the first value is returned due to function clause matching
      assert TestBag.fetch(:a) == {:ok, 1}
      assert TestBag.fetch(:b) == {:ok, 3}

      # keys() shows duplicate keys
      keys = TestBag.keys()
      assert :a in keys
      assert :b in keys
      assert Enum.count(keys, & &1 == :a) == 2  # :a appears twice

      # all() shows all entries
      all_entries = TestBag.all()
      assert length(all_entries) == 3
      assert {:a, 1} in all_entries
      assert {:a, 2} in all_entries
      assert {:b, 3} in all_entries
    end

    test "works with :duplicate_bag tables but only returns first value" do
      :ets.new(:test_dup_bag, [:named_table, :duplicate_bag])
      :ets.insert(:test_dup_bag, {:a, 1})
      :ets.insert(:test_dup_bag, {:a, 2})
      :ets.insert(:test_dup_bag, {:a, 1})  # Creates duplicate
      :ets.insert(:test_dup_bag, {:b, 3})

      {:ok, TestDupBag} = Exfoil.convert(:test_dup_bag)

      # Only the first value is returned
      assert TestDupBag.fetch(:a) == {:ok, 1}
      assert TestDupBag.fetch(:b) == {:ok, 3}

      # keys() shows all duplicate keys
      keys = TestDupBag.keys()
      assert Enum.count(keys, & &1 == :a) == 3  # :a appears three times
      assert Enum.count(keys, & &1 == :b) == 1

      # all() shows all entries including duplicates
      all_entries = TestDupBag.all()
      assert length(all_entries) == 4
      assert Enum.count(all_entries, & &1 == {:a, 1}) == 2  # {:a, 1} appears twice
    end

    test "bang functions work with all table types" do
      [:set, :ordered_set, :bag, :duplicate_bag]
      |> Enum.each(fn table_type ->
        table_name = String.to_atom("test_bang_#{table_type}")
        :ets.new(table_name, [:named_table, table_type])
        :ets.insert(table_name, {:exists, "value"})

        {:ok, module} = Exfoil.convert(table_name)

        # Bang version returns value directly
        assert module.fetch!(:exists) == "value"

        # Bang version raises for missing keys
        assert_raise KeyError, fn ->
          module.fetch!(:missing)
        end
      end)
    end

    test "default values work with all table types" do
      [:set, :ordered_set, :bag, :duplicate_bag]
      |> Enum.each(fn table_type ->
        table_name = String.to_atom("test_default_#{table_type}")
        :ets.new(table_name, [:named_table, table_type])
        :ets.insert(table_name, {:exists, "value"})

        {:ok, module} = Exfoil.convert(table_name)

        # Default value is returned for missing keys
        assert module.get(:missing) == nil
        assert module.get(:missing, :default) == :default
        assert module.get(:missing, %{not: "found"}) == %{not: "found"}

        # Existing keys still return {:ok, value}
        assert module.fetch(:exists) == {:ok, "value"}
        assert module.get(:exists) == "value"
        assert module.get(:exists, :default) == "value"
      end)
    end

    test "complex data types work with all table types" do
      [:set, :ordered_set, :bag, :duplicate_bag]
      |> Enum.each(fn table_type ->
        table_name = String.to_atom("test_complex_#{table_type}")
        :ets.new(table_name, [:named_table, table_type])

        :ets.insert(table_name, {:map, %{name: "Alice", age: 30}})
        :ets.insert(table_name, {:list, [1, 2, 3]})
        :ets.insert(table_name, {:tuple, {:ok, "result"}})

        {:ok, module} = Exfoil.convert(table_name)

        assert module.fetch(:map) == {:ok, %{name: "Alice", age: 30}}
        assert module.fetch(:list) == {:ok, [1, 2, 3]}
        assert module.fetch(:tuple) == {:ok, {:ok, "result"}}

        assert module.fetch!(:map) == %{name: "Alice", age: 30}
        assert module.fetch!(:list) == [1, 2, 3]
        assert module.fetch!(:tuple) == {:ok, "result"}
      end)
    end
  end

  describe "Limitations with multi-value tables" do
    test "bag tables: ETS lookup returns all values, Exfoil returns only first" do
      :ets.new(:bag_comparison, [:named_table, :bag])
      :ets.insert(:bag_comparison, {:key, "first"})
      :ets.insert(:bag_comparison, {:key, "second"})
      :ets.insert(:bag_comparison, {:key, "third"})

      # ETS returns all values
      ets_result = :ets.lookup(:bag_comparison, :key)
      assert length(ets_result) == 3
      assert {:key, "first"} in ets_result
      assert {:key, "second"} in ets_result
      assert {:key, "third"} in ets_result

      # Exfoil only returns the first value
      {:ok, BagComparison} = Exfoil.convert(:bag_comparison)
      assert BagComparison.fetch(:key) == {:ok, "first"}

      # But all() shows all entries
      assert length(BagComparison.all()) == 3
    end

    test "duplicate_bag tables: allows true duplicates but Exfoil returns only first" do
      :ets.new(:dup_bag_comparison, [:named_table, :duplicate_bag])
      :ets.insert(:dup_bag_comparison, {:key, "value"})
      :ets.insert(:dup_bag_comparison, {:key, "value"})  # Exact duplicate
      :ets.insert(:dup_bag_comparison, {:key, "other"})

      # ETS returns all values including duplicates
      ets_result = :ets.lookup(:dup_bag_comparison, :key)
      assert length(ets_result) == 3

      # Exfoil only returns the first value
      {:ok, DupBagComparison} = Exfoil.convert(:dup_bag_comparison)
      assert DupBagComparison.fetch(:key) == {:ok, "value"}

      # all() shows all entries including duplicates
      all_entries = DupBagComparison.all()
      assert length(all_entries) == 3
      assert Enum.count(all_entries, & &1 == {:key, "value"}) == 2
    end
  end
end