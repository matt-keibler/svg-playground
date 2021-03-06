{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
module AnimationConfig (AnimationConfig(..)
                       , ShapeStyle(..)
                       , SVGStyling(..)
                       , SVGShape(..)
                       , SVGAnimation(..)
                       , interpolateSVG
                       , loadConfig)where

import Data.HashMap.Strict (member)
import GHC.Generics
import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as C
import Control.Monad (mzero)

import Animation(Rectangle, Line, Circle, Ellipse, Animatable(..))

defaultFilename :: String
defaultFilename = "/tmp/animation"

defaultFrameSize :: Int
defaultFrameSize = 64

defaultNumFrames :: Int
defaultNumFrames = 10

data ShapeStyle = RectStyle { rx :: String, ry :: String } deriving (Eq, Show, Generic)

instance FromJSON ShapeStyle where
  parseJSON (Object v) = RectStyle <$>
                         v .:? "rx" .!= "0" <*>
                         v .:? "ry" .!= "0"
  parseJSON _ = mzero

data SVGStyling = SVGStyling {
  stroke :: String
  , strokeWidth :: String
  , fill :: String
  , fillOpacity :: String
  , shapeStyle :: Maybe ShapeStyle
  } deriving (Eq, Show, Generic)

instance FromJSON SVGStyling where
  parseJSON (Object v) = SVGStyling <$>
                         v .:? "stroke" .!= "black" <*>
                         v .:? "strokeWidth" .!= "1" <*>
                         v .:? "fill" .!= "white" <*>
                         v .:? "fillOpacity" .!= "1" <*>
                         v .:? "shapeStyle" .!= Nothing
  parseJSON _ = mzero

data SVGShape = SVGLine Line SVGStyling
  | SVGRect Rectangle SVGStyling
  | SVGCircle Circle SVGStyling
  | SVGEllipse Ellipse SVGStyling
  deriving (Eq, Show, Generic)

instance FromJSON SVGShape where
  parseJSON (Object v)
    | member "line" v = SVGLine <$> v .: "line" <*>
                        v .:  "style"
    | member "rect" v = SVGRect <$> v .: "rect" <*>
                        v .:  "style"
    | member "circle" v = SVGCircle <$> v .: "circle" <*>
                          v .:  "style"
    | member "ellipse" v = SVGEllipse <$> v .: "ellipse" <*>
                           v .:  "style"
    | otherwise = mzero
  parseJSON _ = mzero

data SVGAnimation = SVGAnimationLine Line Line SVGStyling
  | SVGAnimationRect Rectangle Rectangle SVGStyling
  | SVGAnimationCircle Circle Circle SVGStyling
  | SVGAnimationEllipse Ellipse Ellipse SVGStyling
  deriving (Eq, Show, Generic)

instance FromJSON SVGAnimation where
  parseJSON (Object v)
    | member "startLine" v = SVGAnimationLine <$> v .: "startLine" <*>
                             v .: "endLine" <*>
                             v .:  "animatedStyle"
    | member "startRect" v = SVGAnimationRect <$> v .: "startRect" <*>
                             v .: "endRect" <*>
                             v .:  "animatedStyle"
    | member "startCircle" v = SVGAnimationCircle <$> v .: "startCircle" <*>
                               v .: "endCircle" <*>
                               v .:  "animatedStyle"
    | member "startEllipse" v = SVGAnimationEllipse <$> v .: "startEllipse" <*>
                                v .: "endEllipse" <*>
                                v .:  "animatedStyle"
    | otherwise = mzero
  parseJSON _ = mzero

interpolateSVG :: Int -> SVGAnimation -> [SVGShape]
interpolateSVG num (SVGAnimationLine lineStart lineEnd style) = map (`SVGLine` style) (animate num lineStart lineEnd)
interpolateSVG num (SVGAnimationRect rectStart rectEnd style) = map (`SVGRect` style) (animate num rectStart rectEnd)
interpolateSVG num (SVGAnimationCircle circleStart circleEnd style) = map (`SVGCircle` style) (animate num circleStart circleEnd)
interpolateSVG num (SVGAnimationEllipse ellipseStart ellipseEnd style) = map (`SVGEllipse` style) (animate num ellipseStart ellipseEnd)

data AnimationConfig = AnimationConfig {
  filename :: String
  , frameWidth :: Int
  , frameHeight :: Int
  , numFrames :: Int
  , staticShapes :: [SVGShape]
  , animatedShapes :: [SVGAnimation]
  } deriving (Eq, Show, Generic)

instance FromJSON AnimationConfig where
  parseJSON (Object v) = AnimationConfig <$>
                         v .:? "filename" .!= defaultFilename <*>
                         v .:? "frameWidth" .!= defaultFrameSize <*>
                         v .:? "frameHeight" .!= defaultFrameSize <*>
                         v .:? "numFrames" .!= defaultNumFrames <*>
                         v .:? "staticShapes" .!= [] <*>
                         v .:? "animatedShapes" .!= []
  parseJSON _ = mzero

loadConfig :: String -> Either String AnimationConfig
loadConfig = eitherDecode . C.pack
