#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Data.Dictionary.BalancedTree do
  alias Data.Protocol, as: P

  defstruct dict: nil

  def new do
    %__MODULE__{dict: :gb_trees.empty}
  end

  def new({ 0, nil } = self) do
    %__MODULE__{dict: self}
  end

  def new({ length, tree } = self) when is_integer(length) and is_tuple(tree) do
    %__MODULE__{dict: self}
  end

  def new(enum) do
    %__MODULE__{dict: Data.to_list(enum) |> :orddict.from_list |> :gb_trees.from_orddict}
  end

  def has_key?(%__MODULE__{dict: self}, key) do
    :gb_trees.is_defined(key, self)
  end

  def fetch(%__MODULE__{dict: self}, key) do
    case :gb_trees.lookup(key, self) do
      { :value, value } ->
        { :ok, value }

      :none ->
        :error
    end
  end

  def put(%__MODULE__{dict: self}, key, value) do
    %__MODULE__{dict: :gb_trees.enter(key, value, self)}
  end

  def put_new(%__MODULE__{dict: self}, key, value) do
    if :gb_trees.is_defined(key, self) do
      %__MODULE__{dict: self}
    else
      %__MODULE__{dict: :gb_trees.insert(key, value, self)}
    end
  end

  def delete(%__MODULE__{dict: self}, key) do
    %__MODULE__{dict: :gb_trees.delete_any(key, self)}
  end

  def keys(%__MODULE__{dict: self}) do
    :gb_trees.keys(self)
  end

  def values(%__MODULE__{dict: self}) do
    :gb_trees.values(self)
  end

  def size(%__MODULE__{dict: self}) do
    :gb_trees.size(self)
  end

  def empty(_) do
    :gb_trees.empty
  end

  def to_list(%__MODULE__{dict: self}) do
    :gb_trees.to_list(self)
  end

  def member?(%__MODULE__{dict: self}, { key, value }) do
    case :gb_trees.lookup(key, self) do
      { :value, ^value } ->
        true

      _ ->
        false
    end
  end

  def member?(%__MODULE__{dict: self}, key) do
    :gb_trees.is_defined(key, self)
  end

  defmodule Sequence do
    defstruct [:iter]

    def new(dict) do
      %__MODULE__{iter: :gb_trees.iterator(dict)}
    end

    def first(%__MODULE__{iter: iter}) do
      case :gb_trees.next(iter) do
        :none ->
          nil

        { key, value, _next } ->
          { key, value }
      end
    end

    def next(%__MODULE__{iter: iter}) do
      case :gb_trees.next(iter) do
        :none ->
          nil

        { _key, _value, next } ->
          %__MODULE__{iter: next}
      end
    end

    defimpl P.Sequence do
      defdelegate first(self), to: Sequence
      defdelegate next(self), to: Sequence
    end
  end

  def to_sequence(%__MODULE__{dict: self}) do
    Sequence.new(self)
  end

  defimpl P.Dictionary do
    defdelegate fetch(self, key), to: Data.Dictionary.BalancedTree
    defdelegate put(self, key, value), to: Data.Dictionary.BalancedTree
    defdelegate delete(self, key), to: Data.Dictionary.BalancedTree
    defdelegate keys(self), to: Data.Dictionary.BalancedTree
    defdelegate values(self), to: Data.Dictionary.BalancedTree
  end

  defimpl P.Count do
    defdelegate count(self), to: Data.Dictionary.BalancedTree, as: :size
  end

  defimpl P.Empty do
    def empty?(self) do
      Data.Dictionary.BalancedTree.size(self) == 0
    end

    defdelegate clear(self), to: Data.Dictionary.BalancedTree, as: :empty
  end

  defimpl P.Reduce do
    def reduce(self, acc, fun) do
      Data.Seq.reduce(self, acc, fun)
    end
  end

  defimpl P.ToList do
    defdelegate to_list(self), to: Data.Dictionary.BalancedTree
  end

  defimpl P.Contains do
    defdelegate contains?(self, key), to: Data.Dictionary.BalancedTree, as: :member?
  end

  defimpl P.ToSequence do
    defdelegate to_sequence(self), to: Data.Dictionary.BalancedTree
  end

  defimpl Enumerable do
    use Data.Enumerable
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(self, opts) do
      concat ["#Dictionary<", Kernel.inspect(Data.Dictionary.BalancedTree.to_list(self), opts), ">"]
    end
  end
end
