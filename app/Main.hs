{-# LANGUAGE OverloadedStrings #-}
module Main where

import Animation

import Graphics.Svg hiding (translate)
import Data.Text hiding (foldr1, index)

import Data.List (zipWith5)

frameWidth :: Int
frameWidth = 64

numFrames :: Int
numFrames = 10

frameLines :: Int -> Line -> Line -> Line -> Line -> (Line, Line, Line, Line)
frameLines index line0 line1 line2 line3 = (translate frameStart line0,
                                            translate frameStart line1,
                                            translate frameStart line2,
                                            translate frameStart line3)
  where frameStart = Point (index * frameWidth) 0

framedLinesToSvg :: (Line, Line, Line, Line) -> Element
framedLinesToSvg (line0, line1, line2, line3) = thickLineSvg line0
                                                <> thickLineSvg line1
                                                <> thinLineSvg line2
                                                <> thinLineSvg line3
  where thickLineSvg = lineToSvg "8" "#990000"
        thinLineSvg = lineToSvg "4" "#cc0000"

main :: IO ()
main = do
  let topBackSlash = linearAnimateLine numFrames (Line (Point 20 20) (Point 44 44)) (Line (Point 26 20) (Point 26 44))
  let topForwardSlash = linearAnimateLine numFrames (Line (Point 20 44) (Point 44 20)) (Line (Point 38 44) (Point 38 20))
  let bottomBackSlash = linearAnimateLine numFrames (Line (Point 16 16) (Point 48 48)) (Line (Point 26 18) (Point 26 46))
  let bottomForwardSlash = linearAnimateLine numFrames (Line (Point 16 48) (Point 48 16)) (Line (Point 38 46) (Point 38 18))
  let lineFrames = foldr1 (<>) $ framedLinesToSvg <$> zipWith5 frameLines [0 ..] bottomBackSlash bottomForwardSlash topBackSlash topForwardSlash
  let file = svg (frames <> lineFrames)
  writeFile "/tmp/spritesheet.svg" $ show file

svg :: Element -> Element
svg content = doctype <> with (svg11_ content) [Version_ <<- "1.1",
                                                Width_ <<- pack (show (frameWidth * numFrames)),
                                                Height_ <<- "64"]

defaultFrame :: Int -> Element
defaultFrame index = rect_ [X_ <<- xPos 2, Y_ <<- "2",
                            Width_ <<- paddedFrame 2, Height_ <<- paddedFrame 2,
                            "#660000" ->> Fill_, Fill_opacity_ <<- "0.5"]
                     <> rect_ [X_ <<- xPos 4, Y_ <<- "4",
                               Width_ <<- paddedFrame 4, Height_ <<- paddedFrame 4,
                               "#990000" ->> Stroke_, Stroke_width_ <<- "8",
                               Fill_opacity_ <<- "0"]
                     <> rect_ [X_ <<- xPos 2, Y_ <<- "2",
                               Width_ <<- paddedFrame 2, Height_ <<- paddedFrame 2,
                               "#cc0000" ->> Stroke_, Stroke_width_ <<- "4",
                               Fill_opacity_ <<- "0"]
  where xPos padding = (pack .show) ((index * frameWidth) + padding)
        paddedFrame padding = (pack . show) (frameWidth - (2 * padding))

frames :: Element
frames = foldr1 (<>) $ fmap defaultFrame [0 .. numFrames]

lineToSvg :: Text -> Text -> Line -> Element
lineToSvg width color(Line (Point xS yS) (Point xE yE)) = line_ [X1_ <<- pack (show xS), Y1_ <<- pack (show yS),
                                                      X2_ <<- pack (show xE), Y2_ <<- pack (show yE),
                                                      Stroke_ <<- color, Stroke_width_ <<- width]
