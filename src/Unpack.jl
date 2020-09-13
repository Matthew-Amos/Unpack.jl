module Unpack

export
    unpack,
    CompileOptions,
    CompiledField,
    @compile

struct CompiledField
    field::Symbol
    # aliases::Vector{Symbol}
    # remap::Tuple{Bool, Symbol}
    # case::Symbol
    # default::Tuple{Bool, Any}
    # skip::Bool
    # key_resolver::Function
    # callback::Function
end

struct CompileOptions
    parent::Symbol
    fields::Vector{CompiledField}
end

unpacker_name(dt) = Symbol(:_UNPACK_, dt)
unpacker_type(dt) = eval(unpacker_name(dt))

unpack() = nothing
unpack(dt::DataType, ustore) = unpack(unpacker_type(dt)(), ustore)


function field_processor(field::CompiledField)
    fnm = QuoteNode(:($(field.field)))
    e = :(us -> us[])
    append!(e.args[2].args[2].args, [fnm])
    e
end

function struct_processor(upk::Symbol, opts::CompileOptions)::Expr
    fn = :(unpack(v::$upk, ustore) = $(opts.parent)())

    for opt in opts.fields
        λ = field_processor(opt)
        append!(fn.args[2].args[2].args, [:($λ(ustore))])
    end

    fn
end

macro compile(ex)
    struct_name = unpacker_name(ex.args[1])
    constructor = :(struct $struct_name end)
    eval(constructor)
    e = struct_processor(struct_name, eval(ex.args[2]))
    eval(e)
end

end # module
