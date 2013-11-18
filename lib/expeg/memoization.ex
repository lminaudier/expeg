defmodule Expeg.Memoization do
  def prepare(name) do
    tid = :ets.new(name, [:set])
    :erlang.put(:memoization_table, tid)
  end

  def table_id do
    :erlang.get(:memoization_table)
  end

  def get(index) do
    :ets.lookup_element(table_id, index, 2)
  end

  def set(index, data) do
    :ets.insert(table_id, {index, data})
  end
end
