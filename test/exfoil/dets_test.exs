defmodule Exfoil.DetsTest do
  use ExUnit.Case
  doctest Exfoil.Dets

  alias Exfoil.Dets

  setup do
    # Create a unique DETS file for each test
    timestamp = System.unique_integer([:positive])
    file_path = "test_dets_#{timestamp}"

    on_exit(fn ->
      # Clean up DETS files after each test
      File.rm(file_path)
      File.rm("#{file_path}.bak")  # DETS may create backup files
    end)

    {:ok, file_path: file_path}
  end

  describe "convert/2" do
    test "converts DETS table to module", %{file_path: file_path} do
      # Open DETS table
      {:ok, table} = :dets.open_file(:test_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])

      # Insert data
      :dets.insert(table, {:a, 1})
      :dets.insert(table, {:b, 2})
      :dets.insert(table, {:c, "hello"})

      # Convert to module
      assert {:ok, module_name} = Dets.convert(:test_dets)
      assert module_name == TestDets

      # Test the generated functions
      assert TestDets.fetch(:a) == {:ok, 1}
      assert TestDets.fetch(:b) == {:ok, 2}
      assert TestDets.fetch(:c) == {:ok, "hello"}
      assert TestDets.get(:nonexistent) == nil

      # Test bang versions
      assert TestDets.fetch!(:a) == 1
      assert TestDets.fetch!(:b) == 2
      assert TestDets.fetch!(:c) == "hello"
      assert_raise KeyError, fn -> TestDets.fetch!(:nonexistent) end

      # Close the table
      :dets.close(table)
    end

    test "handles different data types", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:complex_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])

      :dets.insert(table, {:string, "hello"})
      :dets.insert(table, {:list, [1, 2, 3]})
      :dets.insert(table, {:map, %{key: "value"}})
      :dets.insert(table, {:tuple, {:nested, :tuple}})
      :dets.insert(table, {:atom, :test_atom})
      :dets.insert(table, {:number, 42.5})

      assert {:ok, module_name} = Dets.convert(:complex_dets)
      assert module_name == ComplexDets

      assert ComplexDets.fetch(:string) == {:ok, "hello"}
      assert ComplexDets.fetch(:list) == {:ok, [1, 2, 3]}
      assert ComplexDets.fetch(:map) == {:ok, %{key: "value"}}
      assert ComplexDets.fetch(:tuple) == {:ok, {:nested, :tuple}}
      assert ComplexDets.fetch(:atom) == {:ok, :test_atom}
      assert ComplexDets.fetch(:number) == {:ok, 42.5}

      # Test bang versions
      assert ComplexDets.fetch!(:string) == "hello"
      assert ComplexDets.fetch!(:list) == [1, 2, 3]
      assert ComplexDets.fetch!(:map) == %{key: "value"}

      :dets.close(table)
    end

    test "handles empty DETS table", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:empty_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])

      assert {:ok, module_name} = Dets.convert(:empty_dets)
      assert module_name == EmptyDets

      assert EmptyDets.count() == 0
      assert EmptyDets.keys() == []
      assert EmptyDets.all() == []

      :dets.close(table)
    end

    test "supports custom module name", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:custom_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:key, "value"})

      assert {:ok, module_name} = Dets.convert(:custom_dets, module_name: :CustomModule)
      assert module_name == CustomModule

      assert CustomModule.fetch(:key) == {:ok, "value"}
      assert CustomModule.fetch!(:key) == "value"

      :dets.close(table)
    end

    test "returns error for non-existent table" do
      assert {:error, :table_not_found} = Dets.convert(:non_existent_dets)
    end

    test "default values work correctly", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:default_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:exists, "value"})

      {:ok, DefaultDets} = Dets.convert(:default_dets)

      # Default value is returned for missing keys
      assert DefaultDets.get(:missing) == nil
      assert DefaultDets.get(:missing, :default) == :default
      assert DefaultDets.get(:missing, %{not: "found"}) == %{not: "found"}

      # Existing keys still return {:ok, value}
      assert DefaultDets.fetch(:exists) == {:ok, "value"}
      assert DefaultDets.get(:exists) == "value"

      :dets.close(table)
    end

    test "Map API conformance" do
      # This test explicitly verifies the Map API behavior
      {:ok, table} = :dets.open_file(:api_test, [{:type, :set}])
      :dets.insert(table, {:key, "value"})
      :dets.insert(table, {:number, 42})

      {:ok, ApiTest} = Dets.convert(:api_test)

      # fetch/1 returns {:ok, value} or :error
      assert ApiTest.fetch(:key) == {:ok, "value"}
      assert ApiTest.fetch(:number) == {:ok, 42}
      assert ApiTest.fetch(:missing) == :error

      # fetch!/1 returns value or raises
      assert ApiTest.fetch!(:key) == "value"
      assert ApiTest.fetch!(:number) == 42
      assert_raise KeyError, fn -> ApiTest.fetch!(:missing) end

      # get/2 returns value or default (default is nil)
      assert ApiTest.get(:key) == "value"
      assert ApiTest.get(:number) == 42
      assert ApiTest.get(:missing) == nil
      assert ApiTest.get(:missing, :default) == :default

      :dets.close(table)
    end
  end

  describe "convert!/2" do
    test "returns module name on success", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:bang_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:key, "value"})

      assert module_name = Dets.convert!(:bang_dets)
      assert module_name == BangDets
      assert BangDets.fetch(:key) == {:ok, "value"}
      assert BangDets.fetch!(:key) == "value"

      :dets.close(table)
    end

    test "raises on conversion failure" do
      assert_raise RuntimeError, ~r/Failed to convert DETS table/, fn ->
        Dets.convert!(:non_existent_dets)
      end
    end
  end

  describe "convert_file/3" do
    test "opens file, converts, and optionally closes", %{file_path: file_path} do
      # First create a DETS file with some data
      {:ok, table} = :dets.open_file(:prep_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:a, 1})
      :dets.insert(table, {:b, 2})
      :dets.close(table)

      # Now use convert_file to open and convert it
      assert {:ok, module} = Dets.convert_file(file_path, :file_dets,
                                                module_name: :FileDets,
                                                close_after: true)

      assert module == FileDets
      assert FileDets.fetch(:a) == {:ok, 1}
      assert FileDets.fetch(:b) == {:ok, 2}

      # Verify the table was closed (should not be accessible)
      assert :dets.info(:file_dets) == :undefined
    end

    test "handles file that doesn't exist" do
      # DETS will create the file if it doesn't exist, so we need to test with a bad path
      assert {:error, {:cannot_open_file, _}} = Dets.convert_file("/invalid/path/non_existent.dets", :test)
    end

    test "keeps table open when close_after is false", %{file_path: file_path} do
      # Create a DETS file
      {:ok, table} = :dets.open_file(:prep2_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:key, "value"})
      :dets.close(table)

      # Convert without closing
      assert {:ok, _module} = Dets.convert_file(file_path, :open_dets,
                                                 module_name: :OpenDets,
                                                 close_after: false)

      # Table should still be open
      assert is_list(:dets.info(:open_dets))

      # Clean up
      :dets.close(:open_dets)
    end
  end

  describe "generated module functions" do
    setup %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:test_module, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:a, 1})
      :dets.insert(table, {:b, 2})
      :dets.insert(table, {:c, 3})

      {:ok, module} = Dets.convert(:test_module)

      on_exit(fn -> :dets.close(table) end)

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

  describe "DETS table types" do
    test "works with different DETS table types", %{file_path: file_path} do
      # DETS supports: set, bag, duplicate_bag (no ordered_set)
      [:set, :bag, :duplicate_bag]
      |> Enum.each(fn type ->
        table_name = :"dets_#{type}"
        file = "#{file_path}_#{type}"

        {:ok, table} = :dets.open_file(table_name, [{:file, String.to_charlist(file)}, {:type, type}])
        :dets.insert(table, {:key, "value_#{type}"})

        {:ok, module} = Dets.convert(table_name)

        assert module.fetch(:key) == {:ok, "value_#{type}"}
        assert module.fetch!(:key) == "value_#{type}"

        :dets.close(table)
        File.rm(file)
      end)
    end

    test "handles bag tables with multiple values", %{file_path: file_path} do
      {:ok, table} = :dets.open_file(:bag_dets, [{:file, String.to_charlist(file_path)}, {:type, :bag}])

      :dets.insert(table, {:a, 1})
      :dets.insert(table, {:a, 2})
      :dets.insert(table, {:b, 3})

      {:ok, BagDets} = Dets.convert(:bag_dets)

      # Only the first value is returned (same as ETS behavior)
      assert BagDets.fetch(:a) == {:ok, 1}
      assert BagDets.fetch(:b) == {:ok, 3}

      # all() shows all entries
      all_entries = BagDets.all()
      assert length(all_entries) == 3
      assert {:a, 1} in all_entries
      assert {:a, 2} in all_entries

      :dets.close(table)
    end
  end

  describe "integration test" do
    test "full workflow with persistence", %{file_path: file_path} do
      # Create and populate a DETS table
      {:ok, table} = :dets.open_file(:persist_dets, [{:file, String.to_charlist(file_path)}, {:type, :set}])
      :dets.insert(table, {:config, %{host: "localhost", port: 5432}})
      :dets.insert(table, {:users, ["alice", "bob", "charlie"]})
      :dets.insert(table, {:active, true})
      :dets.close(table)

      # Reopen and convert
      {:ok, _table} = :dets.open_file(:persist_dets, [{:file, String.to_charlist(file_path)}])
      {:ok, PersistDets} = Dets.convert(:persist_dets)

      # Test data persistence
      assert PersistDets.fetch(:config) == {:ok, %{host: "localhost", port: 5432}}
      assert PersistDets.fetch(:users) == {:ok, ["alice", "bob", "charlie"]}
      assert PersistDets.fetch(:active) == {:ok, true}

      assert PersistDets.fetch!(:config) == %{host: "localhost", port: 5432}
      assert PersistDets.fetch!(:users) == ["alice", "bob", "charlie"]
      assert PersistDets.fetch!(:active) == true

      # Helper functions
      assert PersistDets.count() == 3
      keys = PersistDets.keys()
      assert :config in keys
      assert :users in keys
      assert :active in keys

      :dets.close(:persist_dets)
    end
  end
end