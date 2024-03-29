local lpeg = require "lpeg"

local function print_ast(t)
  if t.tag == "Goal" then
    print_Goal(t)
  end
  print("nothing to print")
end

local function table_formula(t)
  if type(t) == "number" then
    return(t)
  elseif type(t) == "string" then
    return(string.format("%s", t))
  elseif type(t) == "table" then
    local s = "{ "
    for k,v in pairs(t) do
      s = s.."[ "..table_formula(k).."="..table_formula(v).." ]"
    end
    s = s.." }"
    return(s)
  else
    print("cannot convert table object")
  end
end

local function getcontents(filename)
  file = assert(io.open(filename, "r"))
  contents = file:read("*a")
  file:close()
  return contents
end

-- Lexical Elements
local function taggedCap(tag, pat)
  return lpeg.Ct(lpeg.Cg(lpeg.Cc(tag), "tag") * pat)
end

local Space = lpeg.S(" \n\t")
local skip = Space^0
local Atom = taggedCap("Atom", lpeg.R("AZ")^1)
local place = taggedCap("Place", lpeg.R("az"))
local neg = taggedCap("Neg", symb("~"))

local function token(pat)
  return pat * skip
end

local function kw(str)
  return token (lpeg.P(str))
end

local function symb(str)
  return token (lpeg.P(str))
end

local BasicTransition = taggedCap("BasicTransition", place * symb("t1") * place + place * place * symb("t2") * place + place * symb("t3") * place * place)

-- Grammar
local composedPN = lpeg.V("composedPN")
local PetriNetProgram = lpeg.P {
    composedPN,
    composedPN = BasicTransition * skip * symb("+") * skip * composedPN + BasicTransition;
  }

local sequence = lpeg.V("sequence")
local Sequence = lpeg.P {
    sequence,
    sequence = place * sequence + place;
  }

local mpn = lpeg.V("mpn")
local MarkedPetriNetProgram = lpeg.P {
    mpn,
    mpn = symb("(") * skip * Sequence * skip * symb(")") * skip * symb(",") * skip * PetriNetProgram;
  }

local dmodality = lpeg.V("dmodality")
local DModality = lpeg.P {
    dmodality,
    dmodality = taggedCap("BDia", symb("<")) * skip * MarkedPetriNetProgram * skip * taggedCap("EDia", symb(">"));
  }

local bmodality = lpeg.V("bmodality")
local BModality = lpeg.P {
    bmodality,
    bmodality = taggedCap("BBox", symb("[")) * skip * MarkedPetriNetProgram * skip * taggedCap("EBox", symb("]"));
  }

local modality = lpeg.V("modality")
local Modality = lpeg.P {
    modality,
    modality = DModality + BModality;
  }

local connective = lpeg.V("connective")
local Connective = lpeg.P {
    connective,
    connective = taggedCap("Connective", symb ("&") + symb("|") + symb("->"));
  }

function parse_input(contents)
  local formula = lpeg.V("formula")
  local form = lpeg.V("form")
  G = lpeg.P {
    formula,
    formula = skip * form * skip;
    form = Modality * form + Atom * Connective * symb("(") * form * symb(")") + symb("(") * form * symb(")") * Connective * form + neg * form + Atom * Connective * Atom + Atom + symb("(") * form * symb(")");
  }
  local t = lpeg.match(G, contents)
  if not t then
    io.write("Not a well-formed formula: ", contents)
    io.write("\n")
    --os.exit(1)
  end
  ast = table_formula(t)
  return(ast)
end
