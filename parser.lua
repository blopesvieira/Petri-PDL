local lpeg = require "lpeg"

local function table_atom(x)
  return (string.format("\"%s\"", x))
end

local function table_formula(f)
  if f.tag == "Atom" then
    return("[ Atom "..table_atom(f[1]).." ]")
  elseif f.tag == "form" then
    return("[ Imp"..table_formula(f[1])..","..table_formula(f[2]).."]")
  end
end

local function table_formulas(t)
  if #t > 0 then
    local s = ""
    for i=1,#t do
      p = p.." ( "..i..table_formula(t[i]).." ) "
    end
  else
    return(t.tag.."empty")
  end
end

print_Goal = function (t)
  io.write("[ Goal ")
  if #t > 0 then
    print_formulas(t[1])
    io.write(" SEQ ")
    print_formulas(t[2])
  end
  io.write("]")
end

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

-- Lexical Elements
local Space = lpeg.S(" \n\t")
local skip = Space^0
local Atom = lpeg.C(lpeg.R("AZ")^1) * skip

local function getcontents(filename)
  file = assert(io.open(filename, "r"))
  contents = file:read("*a")
  file:close()
  return contents
end

local function token(pat)
  return pat * skip
end

local function kw(str)
  return token (lpeg.P(str))
end

local function symb(str)
  return token (lpeg.P(str))
end

local function taggedCap(tag, pat)
  return lpeg.Ct(lpeg.Cg(lpeg.Cc(tag), "tag") * pat)
end

-- Grammar
local place = lpeg.R("az")
local basicPN = lpeg.V("basicPN")
local BasicTransition = lpeg.P {
    basicPN,
    basicPN = place * symb("t1") * place + place * place * symb("t2") * place + place * symb("t3") * place * place;
  }

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
    dmodality = symb("<") * skip * MarkedPetriNetProgram * skip * symb(">");
  }

local bmodality = lpeg.V("bmodality")
local BModality = lpeg.P {
    bmodality,
    bmodality = symb("[") * skip * MarkedPetriNetProgram * skip * symb("]");
  }

local modality = lpeg.V("modality")
local Modality = lpeg.P {
    modality,
    modality = DModality + BModality;
  }

local connective = lpeg.V("connective")
local Connective = lpeg.P {
    connective,
    connective = symb ("&") + symb("|") + symb("->");
  }

local neg = symb("~")

function parse_input(contents)
  local formula = lpeg.V("formula")
  local form = lpeg.V("form")
  G = lpeg.P {
    formula,
    formula = skip * form * skip * -1;
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
