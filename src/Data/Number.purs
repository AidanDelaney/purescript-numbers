-- | Functions for working with PureScripts builtin `Number` type.
module Data.Number
  ( fromString
  , Fraction(..)
  , eqRelative
  , eqApproximate
  , (~=)
  , (≅)
  , neqApproximate
  , (≇)
  , Precision(..)
  , eqAbsolute
  , nan
  , isNaN
  , infinity
  , isFinite
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Math (abs)
import Global as G

-- | Attempt to parse a `Number` using JavaScripts `parseFloat`. Returns
-- | `Nothing` if the parse fails or if the result is not a finite number.
-- |
-- | Example:
-- | ```purs
-- | > fromString "123"
-- | (Just 123.0)
-- |
-- | > fromString "12.34"
-- | (Just 12.34)
-- |
-- | > fromString "1e4"
-- | (Just 10000.0)
-- |
-- | > fromString "1.2e4"
-- | (Just 12000.0)
-- |
-- | > fromString "bad"
-- | Nothing
-- | ```
-- |
-- | Note that `parseFloat` allows for trailing non-digit characters and
-- | whitespace as a prefix:
-- | ```
-- | > fromString "  1.2 ??"
-- | (Just 1.2)
-- | ```
fromString ∷ String → Maybe Number
fromString = G.readFloat >>> check
  where
    check num | isFinite num = Just num
              | otherwise    = Nothing

-- | A newtype for (small) numbers, typically in the range *[0:1]*. It is used
-- | as an argument for `eqRelative`.
newtype Fraction = Fraction Number

-- | Compare two `Number`s and return `true` if they are equal up to the
-- | given *relative* error (`Fraction` parameter).
-- |
-- | This comparison is scale-invariant, i.e. if `eqRelative frac x y`, then
-- | `eqRelative frac (s * x) (s * y)` for a given scale factor `s > 0.0`
-- | (unless one of x, y is exactly `0.0`).
-- |
-- | Note that the relation that `eqRelative frac` induces on `Number` is
-- | not an equivalence relation. It is reflexive and symmetric, but not
-- | transitive.
-- |
-- | Example:
-- | ``` purs
-- | > (eqRelative 0.01) 133.7 133.0
-- | true
-- |
-- | > (eqRelative 0.001) 133.7 133.0
-- | false
-- |
-- | > (eqRelative 0.01) (0.1 + 0.2) 0.3
-- | true
-- | ```
eqRelative ∷ Fraction → Number → Number → Boolean
eqRelative (Fraction frac) 0.0   y =       abs y <= frac
eqRelative (Fraction frac)   x 0.0 =       abs x <= frac
eqRelative (Fraction frac)   x   y = abs (x - y) <= frac * abs (x + y) / 2.0

-- | Test if two numbers are approximately equal, up to a relative difference
-- | of one part in a million:
-- | ``` purs
-- | eqApproximate = eqRelative 1.0e-6
-- | ```
-- |
-- | Example
-- | ``` purs
-- | > 0.1 + 0.2 == 0.3
-- | false
-- |
-- | > 0.1 + 0.2 ≅ 0.3
-- | true
-- | ```
eqApproximate ∷ Number → Number → Boolean
eqApproximate = eqRelative onePPM
  where
    onePPM ∷ Fraction
    onePPM = Fraction 1.0e-6

infix 4 eqApproximate as ~=
infix 4 eqApproximate as ≅

-- | The complement of `eqApproximate`.
neqApproximate ∷ Number → Number → Boolean
neqApproximate x y = not (x ≅ y)

infix 4 neqApproximate as ≇

-- | A newtype for (small) numbers. It is used as an argument for `eqAbsolute`.
newtype Precision = Precision Number

-- | Compare two `Number`s and return `true` if they are equal up to the
-- | given (absolute) precision. Note that this type of comparison is *not*
-- | scale-invariant. The relation induced by (eqAbsolute eps) is symmetric and
-- | reflexive, but not transitive.
-- |
-- | Example:
-- | ``` purs
-- | > (eqAbsolute 1.0) 133.7 133.0
-- | true
-- |
-- | > (eqAbsolute 0.1) 133.7 133.0
-- | false
-- | ```
eqAbsolute ∷ Precision → Number → Number → Boolean
eqAbsolute (Precision precision) x y = abs (x - y) <= precision

-- | Not a number (NaN).
nan ∷ Number
nan = G.nan

-- | Test whether a `Number` is NaN.
isNaN ∷ Number → Boolean
isNaN = G.isNaN

-- | Positive infinity.
infinity ∷ Number
infinity = G.infinity

-- | Test whether a number is finite.
isFinite ∷ Number → Boolean
isFinite = G.isFinite
