defmodule UnnamedTablesTest do
  use ExUnit.Case

  describe "Exfoil with unnamed ETS tables" do
    test "converts unnamed ETS tables using reference" do
      # Create unnamed table (returns a reference)
      table_ref = :ets.new(:unnamed, [:set])
      :ets.insert(table_ref, {:a, 1})
      :ets.insert(table_ref, {:b, 2})
      :ets.insert(table_ref, {:c, 3})

      # Convert using the reference
      assert {:ok, module} = Exfoil.convert(table_ref)

      # Module name should be auto-generated
      module_name = to_string(module)
      assert String.starts_with?(module_name, "Elixir.ExfoilTable")

      # Functions should work normally
      assert module.get(:a) == {:ok, 1}
      assert module.get(:b) == {:ok, 2}
      assert module.get(:c) == {:ok, 3}
      assert module.get(:missing) == nil
      assert module.get(:missing, :default) == :default

      # Bang functions
      assert module.get!(:a) == 1
      assert module.get!(:b) == 2
      assert_raise KeyError, fn -> module.get!(:missing) end

      # Helper functions
      assert module.count() == 3
      assert length(module.keys()) == 3
      assert :a in module.keys()
      assert :b in module.keys()
      assert :c in module.keys()
    end

    test "supports custom module name for unnamed tables" do
      table_ref = :ets.new(:another_unnamed, [:set])
      :ets.insert(table_ref, {:key, "value"})

      {:ok, MyCustomModule} = Exfoil.convert(table_ref, module_name: :MyCustomModule)

      assert MyCustomModule.get(:key) == {:ok, "value"}
      assert MyCustomModule.get!(:key) == "value"
    end

    test "works with different table types when unnamed" do
      [:set, :ordered_set, :bag, :duplicate_bag]
      |> Enum.each(fn table_type ->
        table_ref = :ets.new(:test, [table_type])
        :ets.insert(table_ref, {:key, "value_#{table_type}"})

        {:ok, module} = Exfoil.convert(table_ref)

        assert module.get(:key) == {:ok, "value_#{table_type}"}
        assert module.get!(:key) == "value_#{table_type}"
      end)
    end

    test "generates unique module names for different unnamed tables" do
      # Create two different unnamed tables
      table1 = :ets.new(:table1, [:set])
      :ets.insert(table1, {:a, 1})

      table2 = :ets.new(:table2, [:set])
      :ets.insert(table2, {:b, 2})

      {:ok, module1} = Exfoil.convert(table1)
      {:ok, module2} = Exfoil.convert(table2)

      # Module names should be different
      assert module1 != module2

      # Each module should have its own data
      assert module1.get(:a) == {:ok, 1}
      assert module1.get(:b) == nil

      assert module2.get(:b) == {:ok, 2}
      assert module2.get(:a) == nil
    end

    test "still works with named tables" do
      # Ensure backward compatibility with named tables
      :ets.new(:named_table_test, [:named_table, :set])
      :ets.insert(:named_table_test, {:x, 10})
      :ets.insert(:named_table_test, {:y, 20})

      {:ok, NamedTableTest} = Exfoil.convert(:named_table_test)

      assert NamedTableTest.get(:x) == {:ok, 10}
      assert NamedTableTest.get(:y) == {:ok, 20}
    end

    test "handles complex data in unnamed tables" do
      table_ref = :ets.new(:complex_unnamed, [:set])
      :ets.insert(table_ref, {:map, %{name: "Alice", age: 30}})
      :ets.insert(table_ref, {:list, [1, 2, 3, 4, 5]})
      :ets.insert(table_ref, {:tuple, {:ok, "result"}})
      :ets.insert(table_ref, {:nested, %{data: %{value: 42}}})

      {:ok, module} = Exfoil.convert(table_ref)

      assert module.get(:map) == {:ok, %{name: "Alice", age: 30}}
      assert module.get(:list) == {:ok, [1, 2, 3, 4, 5]}
      assert module.get(:tuple) == {:ok, {:ok, "result"}}
      assert module.get(:nested) == {:ok, %{data: %{value: 42}}}

      assert module.get!(:map) == %{name: "Alice", age: 30}
      assert module.get!(:list) == [1, 2, 3, 4, 5]
      assert module.get!(:tuple) == {:ok, "result"}
      assert module.get!(:nested) == %{data: %{value: 42}}
    end
  end
end