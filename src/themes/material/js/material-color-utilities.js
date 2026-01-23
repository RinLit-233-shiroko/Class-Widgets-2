.pragma library
var MaterialCore = (function (exports) {
    'use strict';

    /******************************************************************************
    Copyright (c) Microsoft Corporation.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
    ***************************************************************************** */
    /* global Reflect, Promise, SuppressedError, Symbol, Iterator */

    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    function __awaiter(thisArg, _arguments, P, generator) {
        function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
        return new (P || (P = Promise))(function (resolve, reject) {
            function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
            function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
            function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
            step((generator = generator.apply(thisArg, _arguments || [])).next());
        });
    }

    function __generator(thisArg, body) {
        var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
        return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
        function verb(n) { return function (v) { return step([n, v]); }; }
        function step(op) {
            if (f) throw new TypeError("Generator is already executing.");
            while (g && (g = 0, op[0] && (_ = 0)), _) try {
                if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
                if (y = 0, t) op = [op[0] & 2, t.value];
                switch (op[0]) {
                    case 0: case 1: t = op; break;
                    case 4: _.label++; return { value: op[1], done: false };
                    case 5: _.label++; y = op[1]; op = [0]; continue;
                    case 7: op = _.ops.pop(); _.trys.pop(); continue;
                    default:
                        if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                        if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                        if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                        if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                        if (t[2]) _.ops.pop();
                        _.trys.pop(); continue;
                }
                op = body.call(thisArg, _);
            } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
            if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
        }
    }

    function __values(o) {
        var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
        if (m) return m.call(o);
        if (o && typeof o.length === "number") return {
            next: function () {
                if (o && i >= o.length) o = void 0;
                return { value: o && o[i++], done: !o };
            }
        };
        throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
    }

    function __read(o, n) {
        var m = typeof Symbol === "function" && o[Symbol.iterator];
        if (!m) return o;
        var i = m.call(o), r, ar = [], e;
        try {
            while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
        }
        catch (error) { e = { error: error }; }
        finally {
            try {
                if (r && !r.done && (m = i["return"])) m.call(i);
            }
            finally { if (e) throw e.error; }
        }
        return ar;
    }

    typeof SuppressedError === "function" ? SuppressedError : function (error, suppressed, message) {
        var e = new Error(message);
        return e.name = "SuppressedError", e.error = error, e.suppressed = suppressed, e;
    };

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // This file is automatically generated. Do not modify it.
    /**
     * Utility methods for mathematical operations.
     */
    /**
     * The signum function.
     *
     * @return 1 if num > 0, -1 if num < 0, and 0 if num = 0
     */
    function signum(num) {
        if (num < 0) {
            return -1;
        }
        else if (num === 0) {
            return 0;
        }
        else {
            return 1;
        }
    }
    /**
     * The linear interpolation function.
     *
     * @return start if amount = 0 and stop if amount = 1
     */
    function lerp(start, stop, amount) {
        return (1.0 - amount) * start + amount * stop;
    }
    /**
     * Clamps an integer between two integers.
     *
     * @return input when min <= input <= max, and either min or max
     * otherwise.
     */
    function clampInt(min, max, input) {
        if (input < min) {
            return min;
        }
        else if (input > max) {
            return max;
        }
        return input;
    }
    /**
     * Clamps an integer between two floating-point numbers.
     *
     * @return input when min <= input <= max, and either min or max
     * otherwise.
     */
    function clampDouble(min, max, input) {
        if (input < min) {
            return min;
        }
        else if (input > max) {
            return max;
        }
        return input;
    }
    /**
     * Sanitizes a degree measure as an integer.
     *
     * @return a degree measure between 0 (inclusive) and 360
     * (exclusive).
     */
    function sanitizeDegreesInt(degrees) {
        degrees = degrees % 360;
        if (degrees < 0) {
            degrees = degrees + 360;
        }
        return degrees;
    }
    /**
     * Sanitizes a degree measure as a floating-point number.
     *
     * @return a degree measure between 0.0 (inclusive) and 360.0
     * (exclusive).
     */
    function sanitizeDegreesDouble(degrees) {
        degrees = degrees % 360.0;
        if (degrees < 0) {
            degrees = degrees + 360.0;
        }
        return degrees;
    }
    /**
     * Sign of direction change needed to travel from one angle to
     * another.
     *
     * For angles that are 180 degrees apart from each other, both
     * directions have the same travel distance, so either direction is
     * shortest. The value 1.0 is returned in this case.
     *
     * @param from The angle travel starts from, in degrees.
     * @param to The angle travel ends at, in degrees.
     * @return -1 if decreasing from leads to the shortest travel
     * distance, 1 if increasing from leads to the shortest travel
     * distance.
     */
    function rotationDirection(from, to) {
        var increasingDifference = sanitizeDegreesDouble(to - from);
        return increasingDifference <= 180.0 ? 1.0 : -1;
    }
    /**
     * Distance of two points on a circle, represented using degrees.
     */
    function differenceDegrees(a, b) {
        return 180.0 - Math.abs(Math.abs(a - b) - 180.0);
    }
    /**
     * Multiplies a 1x3 row vector with a 3x3 matrix.
     */
    function matrixMultiply(row, matrix) {
        var a = row[0] * matrix[0][0] + row[1] * matrix[0][1] + row[2] * matrix[0][2];
        var b = row[0] * matrix[1][0] + row[1] * matrix[1][1] + row[2] * matrix[1][2];
        var c = row[0] * matrix[2][0] + row[1] * matrix[2][1] + row[2] * matrix[2][2];
        return [a, b, c];
    }

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // This file is automatically generated. Do not modify it.
    /**
     * Color science utilities.
     *
     * Utility methods for color science constants and color space
     * conversions that aren't HCT or CAM16.
     */
    var SRGB_TO_XYZ = [
        [0.41233895, 0.35762064, 0.18051042],
        [0.2126, 0.7152, 0.0722],
        [0.01932141, 0.11916382, 0.95034478],
    ];
    var XYZ_TO_SRGB = [
        [
            3.2413774792388685,
            -1.5376652402851851,
            -0.49885366846268053,
        ],
        [
            -0.9691452513005321,
            1.8758853451067872,
            0.04156585616912061,
        ],
        [
            0.05562093689691305,
            -0.20395524564742123,
            1.0571799111220335,
        ],
    ];
    var WHITE_POINT_D65 = [95.047, 100.0, 108.883];
    /**
     * Converts a color from RGB components to ARGB format.
     */
    function argbFromRgb(red, green, blue) {
        return (255 << 24 | (red & 255) << 16 | (green & 255) << 8 | blue & 255) >>>
            0;
    }
    /**
     * Converts a color from linear RGB components to ARGB format.
     */
    function argbFromLinrgb(linrgb) {
        var r = delinearized(linrgb[0]);
        var g = delinearized(linrgb[1]);
        var b = delinearized(linrgb[2]);
        return argbFromRgb(r, g, b);
    }
    /**
     * Returns the alpha component of a color in ARGB format.
     */
    function alphaFromArgb(argb) {
        return argb >> 24 & 255;
    }
    /**
     * Returns the red component of a color in ARGB format.
     */
    function redFromArgb(argb) {
        return argb >> 16 & 255;
    }
    /**
     * Returns the green component of a color in ARGB format.
     */
    function greenFromArgb(argb) {
        return argb >> 8 & 255;
    }
    /**
     * Returns the blue component of a color in ARGB format.
     */
    function blueFromArgb(argb) {
        return argb & 255;
    }
    /**
     * Returns whether a color in ARGB format is opaque.
     */
    function isOpaque(argb) {
        return alphaFromArgb(argb) >= 255;
    }
    /**
     * Converts a color from ARGB to XYZ.
     */
    function argbFromXyz(x, y, z) {
        var matrix = XYZ_TO_SRGB;
        var linearR = matrix[0][0] * x + matrix[0][1] * y + matrix[0][2] * z;
        var linearG = matrix[1][0] * x + matrix[1][1] * y + matrix[1][2] * z;
        var linearB = matrix[2][0] * x + matrix[2][1] * y + matrix[2][2] * z;
        var r = delinearized(linearR);
        var g = delinearized(linearG);
        var b = delinearized(linearB);
        return argbFromRgb(r, g, b);
    }
    /**
     * Converts a color from XYZ to ARGB.
     */
    function xyzFromArgb(argb) {
        var r = linearized(redFromArgb(argb));
        var g = linearized(greenFromArgb(argb));
        var b = linearized(blueFromArgb(argb));
        return matrixMultiply([r, g, b], SRGB_TO_XYZ);
    }
    /**
     * Converts a color represented in Lab color space into an ARGB
     * integer.
     */
    function argbFromLab(l, a, b) {
        var whitePoint = WHITE_POINT_D65;
        var fy = (l + 16.0) / 116.0;
        var fx = a / 500.0 + fy;
        var fz = fy - b / 200.0;
        var xNormalized = labInvf(fx);
        var yNormalized = labInvf(fy);
        var zNormalized = labInvf(fz);
        var x = xNormalized * whitePoint[0];
        var y = yNormalized * whitePoint[1];
        var z = zNormalized * whitePoint[2];
        return argbFromXyz(x, y, z);
    }
    /**
     * Converts a color from ARGB representation to L*a*b*
     * representation.
     *
     * @param argb the ARGB representation of a color
     * @return a Lab object representing the color
     */
    function labFromArgb(argb) {
        var linearR = linearized(redFromArgb(argb));
        var linearG = linearized(greenFromArgb(argb));
        var linearB = linearized(blueFromArgb(argb));
        var matrix = SRGB_TO_XYZ;
        var x = matrix[0][0] * linearR + matrix[0][1] * linearG + matrix[0][2] * linearB;
        var y = matrix[1][0] * linearR + matrix[1][1] * linearG + matrix[1][2] * linearB;
        var z = matrix[2][0] * linearR + matrix[2][1] * linearG + matrix[2][2] * linearB;
        var whitePoint = WHITE_POINT_D65;
        var xNormalized = x / whitePoint[0];
        var yNormalized = y / whitePoint[1];
        var zNormalized = z / whitePoint[2];
        var fx = labF(xNormalized);
        var fy = labF(yNormalized);
        var fz = labF(zNormalized);
        var l = 116.0 * fy - 16;
        var a = 500.0 * (fx - fy);
        var b = 200.0 * (fy - fz);
        return [l, a, b];
    }
    /**
     * Converts an L* value to an ARGB representation.
     *
     * @param lstar L* in L*a*b*
     * @return ARGB representation of grayscale color with lightness
     * matching L*
     */
    function argbFromLstar(lstar) {
        var y = yFromLstar(lstar);
        var component = delinearized(y);
        return argbFromRgb(component, component, component);
    }
    /**
     * Computes the L* value of a color in ARGB representation.
     *
     * @param argb ARGB representation of a color
     * @return L*, from L*a*b*, coordinate of the color
     */
    function lstarFromArgb(argb) {
        var y = xyzFromArgb(argb)[1];
        return 116.0 * labF(y / 100.0) - 16.0;
    }
    /**
     * Converts an L* value to a Y value.
     *
     * L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
     *
     * L* measures perceptual luminance, a linear scale. Y in XYZ
     * measures relative luminance, a logarithmic scale.
     *
     * @param lstar L* in L*a*b*
     * @return Y in XYZ
     */
    function yFromLstar(lstar) {
        return 100.0 * labInvf((lstar + 16.0) / 116.0);
    }
    /**
     * Converts a Y value to an L* value.
     *
     * L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
     *
     * L* measures perceptual luminance, a linear scale. Y in XYZ
     * measures relative luminance, a logarithmic scale.
     *
     * @param y Y in XYZ
     * @return L* in L*a*b*
     */
    function lstarFromY(y) {
        return labF(y / 100.0) * 116.0 - 16.0;
    }
    /**
     * Linearizes an RGB component.
     *
     * @param rgbComponent 0 <= rgb_component <= 255, represents R/G/B
     * channel
     * @return 0.0 <= output <= 100.0, color channel converted to
     * linear RGB space
     */
    function linearized(rgbComponent) {
        var normalized = rgbComponent / 255.0;
        if (normalized <= 0.040449936) {
            return normalized / 12.92 * 100.0;
        }
        else {
            return Math.pow((normalized + 0.055) / 1.055, 2.4) * 100.0;
        }
    }
    /**
     * Delinearizes an RGB component.
     *
     * @param rgbComponent 0.0 <= rgb_component <= 100.0, represents
     * linear R/G/B channel
     * @return 0 <= output <= 255, color channel converted to regular
     * RGB space
     */
    function delinearized(rgbComponent) {
        var normalized = rgbComponent / 100.0;
        var delinearized = 0.0;
        if (normalized <= 0.0031308) {
            delinearized = normalized * 12.92;
        }
        else {
            delinearized = 1.055 * Math.pow(normalized, 1.0 / 2.4) - 0.055;
        }
        return clampInt(0, 255, Math.round(delinearized * 255.0));
    }
    /**
     * Returns the standard white point; white on a sunny day.
     *
     * @return The white point
     */
    function whitePointD65() {
        return WHITE_POINT_D65;
    }
    function labF(t) {
        var e = 216.0 / 24389.0;
        var kappa = 24389.0 / 27.0;
        if (t > e) {
            return Math.pow(t, 1.0 / 3.0);
        }
        else {
            return (kappa * t + 16) / 116;
        }
    }
    function labInvf(ft) {
        var e = 216.0 / 24389.0;
        var kappa = 24389.0 / 27.0;
        var ft3 = ft * ft * ft;
        if (ft3 > e) {
            return ft3;
        }
        else {
            return (116 * ft - 16) / kappa;
        }
    }

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable:class-as-namespace
    /**
     * Utility methods for calculating contrast given two colors, or calculating a
     * color given one color and a contrast ratio.
     *
     * Contrast ratio is calculated using XYZ's Y. When linearized to match human
     * perception, Y becomes HCT's tone and L*a*b*'s' L*. Informally, this is the
     * lightness of a color.
     *
     * Methods refer to tone, T in the the HCT color space.
     * Tone is equivalent to L* in the L*a*b* color space, or L in the LCH color
     * space.
     */
    var Contrast = /** @class */ (function () {
        function Contrast() {
        }
        /**
         * Returns a contrast ratio, which ranges from 1 to 21.
         *
         * @param toneA Tone between 0 and 100. Values outside will be clamped.
         * @param toneB Tone between 0 and 100. Values outside will be clamped.
         */
        Contrast.ratioOfTones = function (toneA, toneB) {
            toneA = clampDouble(0.0, 100.0, toneA);
            toneB = clampDouble(0.0, 100.0, toneB);
            return Contrast.ratioOfYs(yFromLstar(toneA), yFromLstar(toneB));
        };
        Contrast.ratioOfYs = function (y1, y2) {
            var lighter = y1 > y2 ? y1 : y2;
            var darker = (lighter === y2) ? y1 : y2;
            return (lighter + 5.0) / (darker + 5.0);
        };
        /**
         * Returns a tone >= tone parameter that ensures ratio parameter.
         * Return value is between 0 and 100.
         * Returns -1 if ratio cannot be achieved with tone parameter.
         *
         * @param tone Tone return value must contrast with.
         * Range is 0 to 100. Invalid values will result in -1 being returned.
         * @param ratio Contrast ratio of return value and tone.
         * Range is 1 to 21, invalid values have undefined behavior.
         */
        Contrast.lighter = function (tone, ratio) {
            if (tone < 0.0 || tone > 100.0) {
                return -1;
            }
            var darkY = yFromLstar(tone);
            var lightY = ratio * (darkY + 5.0) - 5.0;
            var realContrast = Contrast.ratioOfYs(lightY, darkY);
            var delta = Math.abs(realContrast - ratio);
            if (realContrast < ratio && delta > 0.04) {
                return -1;
            }
            // Ensure gamut mapping, which requires a 'range' on tone, will still result
            // the correct ratio by darkening slightly.
            var returnValue = lstarFromY(lightY) + 0.4;
            if (returnValue < 0 || returnValue > 100) {
                return -1;
            }
            return returnValue;
        };
        /**
         * Returns a tone <= tone parameter that ensures ratio parameter.
         * Return value is between 0 and 100.
         * Returns -1 if ratio cannot be achieved with tone parameter.
         *
         * @param tone Tone return value must contrast with.
         * Range is 0 to 100. Invalid values will result in -1 being returned.
         * @param ratio Contrast ratio of return value and tone.
         * Range is 1 to 21, invalid values have undefined behavior.
         */
        Contrast.darker = function (tone, ratio) {
            if (tone < 0.0 || tone > 100.0) {
                return -1;
            }
            var lightY = yFromLstar(tone);
            var darkY = ((lightY + 5.0) / ratio) - 5.0;
            var realContrast = Contrast.ratioOfYs(lightY, darkY);
            var delta = Math.abs(realContrast - ratio);
            if (realContrast < ratio && delta > 0.04) {
                return -1;
            }
            // Ensure gamut mapping, which requires a 'range' on tone, will still result
            // the correct ratio by darkening slightly.
            var returnValue = lstarFromY(darkY) - 0.4;
            if (returnValue < 0 || returnValue > 100) {
                return -1;
            }
            return returnValue;
        };
        /**
         * Returns a tone >= tone parameter that ensures ratio parameter.
         * Return value is between 0 and 100.
         * Returns 100 if ratio cannot be achieved with tone parameter.
         *
         * This method is unsafe because the returned value is guaranteed to be in
         * bounds for tone, i.e. between 0 and 100. However, that value may not reach
         * the ratio with tone. For example, there is no color lighter than T100.
         *
         * @param tone Tone return value must contrast with.
         * Range is 0 to 100. Invalid values will result in 100 being returned.
         * @param ratio Desired contrast ratio of return value and tone parameter.
         * Range is 1 to 21, invalid values have undefined behavior.
         */
        Contrast.lighterUnsafe = function (tone, ratio) {
            var lighterSafe = Contrast.lighter(tone, ratio);
            return (lighterSafe < 0.0) ? 100.0 : lighterSafe;
        };
        /**
         * Returns a tone >= tone parameter that ensures ratio parameter.
         * Return value is between 0 and 100.
         * Returns 100 if ratio cannot be achieved with tone parameter.
         *
         * This method is unsafe because the returned value is guaranteed to be in
         * bounds for tone, i.e. between 0 and 100. However, that value may not reach
         * the [ratio with [tone]. For example, there is no color darker than T0.
         *
         * @param tone Tone return value must contrast with.
         * Range is 0 to 100. Invalid values will result in 0 being returned.
         * @param ratio Desired contrast ratio of return value and tone parameter.
         * Range is 1 to 21, invalid values have undefined behavior.
         */
        Contrast.darkerUnsafe = function (tone, ratio) {
            var darkerSafe = Contrast.darker(tone, ratio);
            return (darkerSafe < 0.0) ? 0.0 : darkerSafe;
        };
        return Contrast;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * In traditional color spaces, a color can be identified solely by the
     * observer's measurement of the color. Color appearance models such as CAM16
     * also use information about the environment where the color was
     * observed, known as the viewing conditions.
     *
     * For example, white under the traditional assumption of a midday sun white
     * point is accurately measured as a slightly chromatic blue by CAM16. (roughly,
     * hue 203, chroma 3, lightness 100)
     *
     * This class caches intermediate values of the CAM16 conversion process that
     * depend only on viewing conditions, enabling speed ups.
     */
    var ViewingConditions = /** @class */ (function () {
        /**
         * Parameters are intermediate values of the CAM16 conversion process. Their
         * names are shorthand for technical color science terminology, this class
         * would not benefit from documenting them individually. A brief overview
         * is available in the CAM16 specification, and a complete overview requires
         * a color science textbook, such as Fairchild's Color Appearance Models.
         */
        function ViewingConditions(n, aw, nbb, ncb, c, nc, rgbD, fl, fLRoot, z) {
            this.n = n;
            this.aw = aw;
            this.nbb = nbb;
            this.ncb = ncb;
            this.c = c;
            this.nc = nc;
            this.rgbD = rgbD;
            this.fl = fl;
            this.fLRoot = fLRoot;
            this.z = z;
        }
        /**
         * Create ViewingConditions from a simple, physically relevant, set of
         * parameters.
         *
         * @param whitePoint White point, measured in the XYZ color space.
         *     default = D65, or sunny day afternoon
         * @param adaptingLuminance The luminance of the adapting field. Informally,
         *     how bright it is in the room where the color is viewed. Can be
         *     calculated from lux by multiplying lux by 0.0586. default = 11.72,
         *     or 200 lux.
         * @param backgroundLstar The lightness of the area surrounding the color.
         *     measured by L* in L*a*b*. default = 50.0
         * @param surround A general description of the lighting surrounding the
         *     color. 0 is pitch dark, like watching a movie in a theater. 1.0 is a
         *     dimly light room, like watching TV at home at night. 2.0 means there
         *     is no difference between the lighting on the color and around it.
         *     default = 2.0
         * @param discountingIlluminant Whether the eye accounts for the tint of the
         *     ambient lighting, such as knowing an apple is still red in green light.
         *     default = false, the eye does not perform this process on
         *       self-luminous objects like displays.
         */
        ViewingConditions.make = function (whitePoint, adaptingLuminance, backgroundLstar, surround, discountingIlluminant) {
            if (whitePoint === void 0) { whitePoint = whitePointD65(); }
            if (adaptingLuminance === void 0) { adaptingLuminance = (200.0 / Math.PI) * yFromLstar(50.0) / 100.0; }
            if (backgroundLstar === void 0) { backgroundLstar = 50.0; }
            if (surround === void 0) { surround = 2.0; }
            if (discountingIlluminant === void 0) { discountingIlluminant = false; }
            var xyz = whitePoint;
            var rW = xyz[0] * 0.401288 + xyz[1] * 0.650173 + xyz[2] * -0.051461;
            var gW = xyz[0] * -0.250268 + xyz[1] * 1.204414 + xyz[2] * 0.045854;
            var bW = xyz[0] * -2079e-6 + xyz[1] * 0.048952 + xyz[2] * 0.953127;
            var f = 0.8 + surround / 10.0;
            var c = f >= 0.9 ? lerp(0.59, 0.69, (f - 0.9) * 10.0) :
                lerp(0.525, 0.59, (f - 0.8) * 10.0);
            var d = discountingIlluminant ?
                1.0 :
                f * (1.0 - (1.0 / 3.6) * Math.exp((-adaptingLuminance - 42.0) / 92.0));
            d = d > 1.0 ? 1.0 : d < 0.0 ? 0.0 : d;
            var nc = f;
            var rgbD = [
                d * (100.0 / rW) + 1.0 - d,
                d * (100.0 / gW) + 1.0 - d,
                d * (100.0 / bW) + 1.0 - d,
            ];
            var k = 1.0 / (5.0 * adaptingLuminance + 1.0);
            var k4 = k * k * k * k;
            var k4F = 1.0 - k4;
            var fl = k4 * adaptingLuminance +
                0.1 * k4F * k4F * Math.cbrt(5.0 * adaptingLuminance);
            var n = yFromLstar(backgroundLstar) / whitePoint[1];
            var z = 1.48 + Math.sqrt(n);
            var nbb = 0.725 / Math.pow(n, 0.2);
            var ncb = nbb;
            var rgbAFactors = [
                Math.pow((fl * rgbD[0] * rW) / 100.0, 0.42),
                Math.pow((fl * rgbD[1] * gW) / 100.0, 0.42),
                Math.pow((fl * rgbD[2] * bW) / 100.0, 0.42),
            ];
            var rgbA = [
                (400.0 * rgbAFactors[0]) / (rgbAFactors[0] + 27.13),
                (400.0 * rgbAFactors[1]) / (rgbAFactors[1] + 27.13),
                (400.0 * rgbAFactors[2]) / (rgbAFactors[2] + 27.13),
            ];
            var aw = (2.0 * rgbA[0] + rgbA[1] + 0.05 * rgbA[2]) * nbb;
            return new ViewingConditions(n, aw, nbb, ncb, c, nc, rgbD, fl, Math.pow(fl, 0.25), z);
        };
        /** sRGB-like viewing conditions.  */
        ViewingConditions.DEFAULT = ViewingConditions.make();
        return ViewingConditions;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * CAM16, a color appearance model. Colors are not just defined by their hex
     * code, but rather, a hex code and viewing conditions.
     *
     * CAM16 instances also have coordinates in the CAM16-UCS space, called J*, a*,
     * b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
     * specification, and should be used when measuring distances between colors.
     *
     * In traditional color spaces, a color can be identified solely by the
     * observer's measurement of the color. Color appearance models such as CAM16
     * also use information about the environment where the color was
     * observed, known as the viewing conditions.
     *
     * For example, white under the traditional assumption of a midday sun white
     * point is accurately measured as a slightly chromatic blue by CAM16. (roughly,
     * hue 203, chroma 3, lightness 100)
     */
    var Cam16 = /** @class */ (function () {
        /**
         * All of the CAM16 dimensions can be calculated from 3 of the dimensions, in
         * the following combinations:
         *      -  {j or q} and {c, m, or s} and hue
         *      - jstar, astar, bstar
         * Prefer using a static method that constructs from 3 of those dimensions.
         * This constructor is intended for those methods to use to return all
         * possible dimensions.
         *
         * @param hue
         * @param chroma informally, colorfulness / color intensity. like saturation
         *     in HSL, except perceptually accurate.
         * @param j lightness
         * @param q brightness; ratio of lightness to white point's lightness
         * @param m colorfulness
         * @param s saturation; ratio of chroma to white point's chroma
         * @param jstar CAM16-UCS J coordinate
         * @param astar CAM16-UCS a coordinate
         * @param bstar CAM16-UCS b coordinate
         */
        function Cam16(hue, chroma, j, q, m, s, jstar, astar, bstar) {
            this.hue = hue;
            this.chroma = chroma;
            this.j = j;
            this.q = q;
            this.m = m;
            this.s = s;
            this.jstar = jstar;
            this.astar = astar;
            this.bstar = bstar;
        }
        /**
         * CAM16 instances also have coordinates in the CAM16-UCS space, called J*,
         * a*, b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
         * specification, and is used to measure distances between colors.
         */
        Cam16.prototype.distance = function (other) {
            var dJ = this.jstar - other.jstar;
            var dA = this.astar - other.astar;
            var dB = this.bstar - other.bstar;
            var dEPrime = Math.sqrt(dJ * dJ + dA * dA + dB * dB);
            var dE = 1.41 * Math.pow(dEPrime, 0.63);
            return dE;
        };
        /**
         * @param argb ARGB representation of a color.
         * @return CAM16 color, assuming the color was viewed in default viewing
         *     conditions.
         */
        Cam16.fromInt = function (argb) {
            return Cam16.fromIntInViewingConditions(argb, ViewingConditions.DEFAULT);
        };
        /**
         * @param argb ARGB representation of a color.
         * @param viewingConditions Information about the environment where the color
         *     was observed.
         * @return CAM16 color.
         */
        Cam16.fromIntInViewingConditions = function (argb, viewingConditions) {
            var red = (argb & 0x00ff0000) >> 16;
            var green = (argb & 0x0000ff00) >> 8;
            var blue = (argb & 0x000000ff);
            var redL = linearized(red);
            var greenL = linearized(green);
            var blueL = linearized(blue);
            var x = 0.41233895 * redL + 0.35762064 * greenL + 0.18051042 * blueL;
            var y = 0.2126 * redL + 0.7152 * greenL + 0.0722 * blueL;
            var z = 0.01932141 * redL + 0.11916382 * greenL + 0.95034478 * blueL;
            var rC = 0.401288 * x + 0.650173 * y - 0.051461 * z;
            var gC = -0.250268 * x + 1.204414 * y + 0.045854 * z;
            var bC = -2079e-6 * x + 0.048952 * y + 0.953127 * z;
            var rD = viewingConditions.rgbD[0] * rC;
            var gD = viewingConditions.rgbD[1] * gC;
            var bD = viewingConditions.rgbD[2] * bC;
            var rAF = Math.pow((viewingConditions.fl * Math.abs(rD)) / 100.0, 0.42);
            var gAF = Math.pow((viewingConditions.fl * Math.abs(gD)) / 100.0, 0.42);
            var bAF = Math.pow((viewingConditions.fl * Math.abs(bD)) / 100.0, 0.42);
            var rA = (signum(rD) * 400.0 * rAF) / (rAF + 27.13);
            var gA = (signum(gD) * 400.0 * gAF) / (gAF + 27.13);
            var bA = (signum(bD) * 400.0 * bAF) / (bAF + 27.13);
            var a = (11.0 * rA + -12 * gA + bA) / 11.0;
            var b = (rA + gA - 2.0 * bA) / 9.0;
            var u = (20.0 * rA + 20.0 * gA + 21.0 * bA) / 20.0;
            var p2 = (40.0 * rA + 20.0 * gA + bA) / 20.0;
            var atan2 = Math.atan2(b, a);
            var atanDegrees = (atan2 * 180.0) / Math.PI;
            var hue = sanitizeDegreesDouble(atanDegrees);
            var hueRadians = (hue * Math.PI) / 180.0;
            var ac = p2 * viewingConditions.nbb;
            var j = 100.0 *
                Math.pow(ac / viewingConditions.aw, viewingConditions.c * viewingConditions.z);
            var q = (4.0 / viewingConditions.c) * Math.sqrt(j / 100.0) *
                (viewingConditions.aw + 4.0) * viewingConditions.fLRoot;
            var huePrime = hue < 20.14 ? hue + 360 : hue;
            var eHue = 0.25 * (Math.cos((huePrime * Math.PI) / 180.0 + 2.0) + 3.8);
            var p1 = (50000.0 / 13.0) * eHue * viewingConditions.nc * viewingConditions.ncb;
            var t = (p1 * Math.sqrt(a * a + b * b)) / (u + 0.305);
            var alpha = Math.pow(t, 0.9) *
                Math.pow(1.64 - Math.pow(0.29, viewingConditions.n), 0.73);
            var c = alpha * Math.sqrt(j / 100.0);
            var m = c * viewingConditions.fLRoot;
            var s = 50.0 *
                Math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));
            var jstar = ((1.0 + 100.0 * 0.007) * j) / (1.0 + 0.007 * j);
            var mstar = (1.0 / 0.0228) * Math.log(1.0 + 0.0228 * m);
            var astar = mstar * Math.cos(hueRadians);
            var bstar = mstar * Math.sin(hueRadians);
            return new Cam16(hue, c, j, q, m, s, jstar, astar, bstar);
        };
        /**
         * @param j CAM16 lightness
         * @param c CAM16 chroma
         * @param h CAM16 hue
         */
        Cam16.fromJch = function (j, c, h) {
            return Cam16.fromJchInViewingConditions(j, c, h, ViewingConditions.DEFAULT);
        };
        /**
         * @param j CAM16 lightness
         * @param c CAM16 chroma
         * @param h CAM16 hue
         * @param viewingConditions Information about the environment where the color
         *     was observed.
         */
        Cam16.fromJchInViewingConditions = function (j, c, h, viewingConditions) {
            var q = (4.0 / viewingConditions.c) * Math.sqrt(j / 100.0) *
                (viewingConditions.aw + 4.0) * viewingConditions.fLRoot;
            var m = c * viewingConditions.fLRoot;
            var alpha = c / Math.sqrt(j / 100.0);
            var s = 50.0 *
                Math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));
            var hueRadians = (h * Math.PI) / 180.0;
            var jstar = ((1.0 + 100.0 * 0.007) * j) / (1.0 + 0.007 * j);
            var mstar = (1.0 / 0.0228) * Math.log(1.0 + 0.0228 * m);
            var astar = mstar * Math.cos(hueRadians);
            var bstar = mstar * Math.sin(hueRadians);
            return new Cam16(h, c, j, q, m, s, jstar, astar, bstar);
        };
        /**
         * @param jstar CAM16-UCS lightness.
         * @param astar CAM16-UCS a dimension. Like a* in L*a*b*, it is a Cartesian
         *     coordinate on the Y axis.
         * @param bstar CAM16-UCS b dimension. Like a* in L*a*b*, it is a Cartesian
         *     coordinate on the X axis.
         */
        Cam16.fromUcs = function (jstar, astar, bstar) {
            return Cam16.fromUcsInViewingConditions(jstar, astar, bstar, ViewingConditions.DEFAULT);
        };
        /**
         * @param jstar CAM16-UCS lightness.
         * @param astar CAM16-UCS a dimension. Like a* in L*a*b*, it is a Cartesian
         *     coordinate on the Y axis.
         * @param bstar CAM16-UCS b dimension. Like a* in L*a*b*, it is a Cartesian
         *     coordinate on the X axis.
         * @param viewingConditions Information about the environment where the color
         *     was observed.
         */
        Cam16.fromUcsInViewingConditions = function (jstar, astar, bstar, viewingConditions) {
            var a = astar;
            var b = bstar;
            var m = Math.sqrt(a * a + b * b);
            var M = (Math.exp(m * 0.0228) - 1.0) / 0.0228;
            var c = M / viewingConditions.fLRoot;
            var h = Math.atan2(b, a) * (180.0 / Math.PI);
            if (h < 0.0) {
                h += 360.0;
            }
            var j = jstar / (1 - (jstar - 100) * 0.007);
            return Cam16.fromJchInViewingConditions(j, c, h, viewingConditions);
        };
        /**
         *  @return ARGB representation of color, assuming the color was viewed in
         *     default viewing conditions, which are near-identical to the default
         *     viewing conditions for sRGB.
         */
        Cam16.prototype.toInt = function () {
            return this.viewed(ViewingConditions.DEFAULT);
        };
        /**
         * @param viewingConditions Information about the environment where the color
         *     will be viewed.
         * @return ARGB representation of color
         */
        Cam16.prototype.viewed = function (viewingConditions) {
            var alpha = this.chroma === 0.0 || this.j === 0.0 ?
                0.0 :
                this.chroma / Math.sqrt(this.j / 100.0);
            var t = Math.pow(alpha / Math.pow(1.64 - Math.pow(0.29, viewingConditions.n), 0.73), 1.0 / 0.9);
            var hRad = (this.hue * Math.PI) / 180.0;
            var eHue = 0.25 * (Math.cos(hRad + 2.0) + 3.8);
            var ac = viewingConditions.aw *
                Math.pow(this.j / 100.0, 1.0 / viewingConditions.c / viewingConditions.z);
            var p1 = eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb;
            var p2 = ac / viewingConditions.nbb;
            var hSin = Math.sin(hRad);
            var hCos = Math.cos(hRad);
            var gamma = (23.0 * (p2 + 0.305) * t) /
                (23.0 * p1 + 11.0 * t * hCos + 108.0 * t * hSin);
            var a = gamma * hCos;
            var b = gamma * hSin;
            var rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
            var gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
            var bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
            var rCBase = Math.max(0, (27.13 * Math.abs(rA)) / (400.0 - Math.abs(rA)));
            var rC = signum(rA) * (100.0 / viewingConditions.fl) *
                Math.pow(rCBase, 1.0 / 0.42);
            var gCBase = Math.max(0, (27.13 * Math.abs(gA)) / (400.0 - Math.abs(gA)));
            var gC = signum(gA) * (100.0 / viewingConditions.fl) *
                Math.pow(gCBase, 1.0 / 0.42);
            var bCBase = Math.max(0, (27.13 * Math.abs(bA)) / (400.0 - Math.abs(bA)));
            var bC = signum(bA) * (100.0 / viewingConditions.fl) *
                Math.pow(bCBase, 1.0 / 0.42);
            var rF = rC / viewingConditions.rgbD[0];
            var gF = gC / viewingConditions.rgbD[1];
            var bF = bC / viewingConditions.rgbD[2];
            var x = 1.86206786 * rF - 1.01125463 * gF + 0.14918677 * bF;
            var y = 0.38752654 * rF + 0.62144744 * gF - 0.00897398 * bF;
            var z = -0.0158415 * rF - 0.03412294 * gF + 1.04996444 * bF;
            var argb = argbFromXyz(x, y, z);
            return argb;
        };
        /// Given color expressed in XYZ and viewed in [viewingConditions], convert to
        /// CAM16.
        Cam16.fromXyzInViewingConditions = function (x, y, z, viewingConditions) {
            // Transform XYZ to 'cone'/'rgb' responses
            var rC = 0.401288 * x + 0.650173 * y - 0.051461 * z;
            var gC = -0.250268 * x + 1.204414 * y + 0.045854 * z;
            var bC = -2079e-6 * x + 0.048952 * y + 0.953127 * z;
            // Discount illuminant
            var rD = viewingConditions.rgbD[0] * rC;
            var gD = viewingConditions.rgbD[1] * gC;
            var bD = viewingConditions.rgbD[2] * bC;
            // chromatic adaptation
            var rAF = Math.pow(viewingConditions.fl * Math.abs(rD) / 100.0, 0.42);
            var gAF = Math.pow(viewingConditions.fl * Math.abs(gD) / 100.0, 0.42);
            var bAF = Math.pow(viewingConditions.fl * Math.abs(bD) / 100.0, 0.42);
            var rA = signum(rD) * 400.0 * rAF / (rAF + 27.13);
            var gA = signum(gD) * 400.0 * gAF / (gAF + 27.13);
            var bA = signum(bD) * 400.0 * bAF / (bAF + 27.13);
            // redness-greenness
            var a = (11.0 * rA + -12 * gA + bA) / 11.0;
            // yellowness-blueness
            var b = (rA + gA - 2.0 * bA) / 9.0;
            // auxiliary components
            var u = (20.0 * rA + 20.0 * gA + 21.0 * bA) / 20.0;
            var p2 = (40.0 * rA + 20.0 * gA + bA) / 20.0;
            // hue
            var atan2 = Math.atan2(b, a);
            var atanDegrees = atan2 * 180.0 / Math.PI;
            var hue = atanDegrees < 0 ? atanDegrees + 360.0 :
                atanDegrees >= 360 ? atanDegrees - 360 :
                    atanDegrees;
            var hueRadians = hue * Math.PI / 180.0;
            // achromatic response to color
            var ac = p2 * viewingConditions.nbb;
            // CAM16 lightness and brightness
            var J = 100.0 *
                Math.pow(ac / viewingConditions.aw, viewingConditions.c * viewingConditions.z);
            var Q = (4.0 / viewingConditions.c) * Math.sqrt(J / 100.0) *
                (viewingConditions.aw + 4.0) * (viewingConditions.fLRoot);
            var huePrime = (hue < 20.14) ? hue + 360 : hue;
            var eHue = (1.0 / 4.0) * (Math.cos(huePrime * Math.PI / 180.0 + 2.0) + 3.8);
            var p1 = 50000.0 / 13.0 * eHue * viewingConditions.nc * viewingConditions.ncb;
            var t = p1 * Math.sqrt(a * a + b * b) / (u + 0.305);
            var alpha = Math.pow(t, 0.9) *
                Math.pow(1.64 - Math.pow(0.29, viewingConditions.n), 0.73);
            // CAM16 chroma, colorfulness, chroma
            var C = alpha * Math.sqrt(J / 100.0);
            var M = C * viewingConditions.fLRoot;
            var s = 50.0 *
                Math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));
            // CAM16-UCS components
            var jstar = (1.0 + 100.0 * 0.007) * J / (1.0 + 0.007 * J);
            var mstar = Math.log(1.0 + 0.0228 * M) / 0.0228;
            var astar = mstar * Math.cos(hueRadians);
            var bstar = mstar * Math.sin(hueRadians);
            return new Cam16(hue, C, J, Q, M, s, jstar, astar, bstar);
        };
        /// XYZ representation of CAM16 seen in [viewingConditions].
        Cam16.prototype.xyzInViewingConditions = function (viewingConditions) {
            var alpha = (this.chroma === 0.0 || this.j === 0.0) ?
                0.0 :
                this.chroma / Math.sqrt(this.j / 100.0);
            var t = Math.pow(alpha / Math.pow(1.64 - Math.pow(0.29, viewingConditions.n), 0.73), 1.0 / 0.9);
            var hRad = this.hue * Math.PI / 180.0;
            var eHue = 0.25 * (Math.cos(hRad + 2.0) + 3.8);
            var ac = viewingConditions.aw *
                Math.pow(this.j / 100.0, 1.0 / viewingConditions.c / viewingConditions.z);
            var p1 = eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb;
            var p2 = (ac / viewingConditions.nbb);
            var hSin = Math.sin(hRad);
            var hCos = Math.cos(hRad);
            var gamma = 23.0 * (p2 + 0.305) * t /
                (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
            var a = gamma * hCos;
            var b = gamma * hSin;
            var rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
            var gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
            var bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
            var rCBase = Math.max(0, (27.13 * Math.abs(rA)) / (400.0 - Math.abs(rA)));
            var rC = signum(rA) * (100.0 / viewingConditions.fl) *
                Math.pow(rCBase, 1.0 / 0.42);
            var gCBase = Math.max(0, (27.13 * Math.abs(gA)) / (400.0 - Math.abs(gA)));
            var gC = signum(gA) * (100.0 / viewingConditions.fl) *
                Math.pow(gCBase, 1.0 / 0.42);
            var bCBase = Math.max(0, (27.13 * Math.abs(bA)) / (400.0 - Math.abs(bA)));
            var bC = signum(bA) * (100.0 / viewingConditions.fl) *
                Math.pow(bCBase, 1.0 / 0.42);
            var rF = rC / viewingConditions.rgbD[0];
            var gF = gC / viewingConditions.rgbD[1];
            var bF = bC / viewingConditions.rgbD[2];
            var x = 1.86206786 * rF - 1.01125463 * gF + 0.14918677 * bF;
            var y = 0.38752654 * rF + 0.62144744 * gF - 0.00897398 * bF;
            var z = -0.0158415 * rF - 0.03412294 * gF + 1.04996444 * bF;
            return [x, y, z];
        };
        return Cam16;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // This file is automatically generated. Do not modify it.
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable:class-as-namespace
    /**
     * A class that solves the HCT equation.
     */
    var HctSolver = /** @class */ (function () {
        function HctSolver() {
        }
        /**
         * Sanitizes a small enough angle in radians.
         *
         * @param angle An angle in radians; must not deviate too much
         * from 0.
         * @return A coterminal angle between 0 and 2pi.
         */
        HctSolver.sanitizeRadians = function (angle) {
            return (angle + Math.PI * 8) % (Math.PI * 2);
        };
        /**
         * Delinearizes an RGB component, returning a floating-point
         * number.
         *
         * @param rgbComponent 0.0 <= rgb_component <= 100.0, represents
         * linear R/G/B channel
         * @return 0.0 <= output <= 255.0, color channel converted to
         * regular RGB space
         */
        HctSolver.trueDelinearized = function (rgbComponent) {
            var normalized = rgbComponent / 100.0;
            var delinearized = 0.0;
            if (normalized <= 0.0031308) {
                delinearized = normalized * 12.92;
            }
            else {
                delinearized = 1.055 * Math.pow(normalized, 1.0 / 2.4) - 0.055;
            }
            return delinearized * 255.0;
        };
        HctSolver.chromaticAdaptation = function (component) {
            var af = Math.pow(Math.abs(component), 0.42);
            return signum(component) * 400.0 * af / (af + 27.13);
        };
        /**
         * Returns the hue of a linear RGB color in CAM16.
         *
         * @param linrgb The linear RGB coordinates of a color.
         * @return The hue of the color in CAM16, in radians.
         */
        HctSolver.hueOf = function (linrgb) {
            var scaledDiscount = matrixMultiply(linrgb, HctSolver.SCALED_DISCOUNT_FROM_LINRGB);
            var rA = HctSolver.chromaticAdaptation(scaledDiscount[0]);
            var gA = HctSolver.chromaticAdaptation(scaledDiscount[1]);
            var bA = HctSolver.chromaticAdaptation(scaledDiscount[2]);
            // redness-greenness
            var a = (11.0 * rA + -12 * gA + bA) / 11.0;
            // yellowness-blueness
            var b = (rA + gA - 2.0 * bA) / 9.0;
            return Math.atan2(b, a);
        };
        HctSolver.areInCyclicOrder = function (a, b, c) {
            var deltaAB = HctSolver.sanitizeRadians(b - a);
            var deltaAC = HctSolver.sanitizeRadians(c - a);
            return deltaAB < deltaAC;
        };
        /**
         * Solves the lerp equation.
         *
         * @param source The starting number.
         * @param mid The number in the middle.
         * @param target The ending number.
         * @return A number t such that lerp(source, target, t) = mid.
         */
        HctSolver.intercept = function (source, mid, target) {
            return (mid - source) / (target - source);
        };
        HctSolver.lerpPoint = function (source, t, target) {
            return [
                source[0] + (target[0] - source[0]) * t,
                source[1] + (target[1] - source[1]) * t,
                source[2] + (target[2] - source[2]) * t,
            ];
        };
        /**
         * Intersects a segment with a plane.
         *
         * @param source The coordinates of point A.
         * @param coordinate The R-, G-, or B-coordinate of the plane.
         * @param target The coordinates of point B.
         * @param axis The axis the plane is perpendicular with. (0: R, 1:
         * G, 2: B)
         * @return The intersection point of the segment AB with the plane
         * R=coordinate, G=coordinate, or B=coordinate
         */
        HctSolver.setCoordinate = function (source, coordinate, target, axis) {
            var t = HctSolver.intercept(source[axis], coordinate, target[axis]);
            return HctSolver.lerpPoint(source, t, target);
        };
        HctSolver.isBounded = function (x) {
            return 0.0 <= x && x <= 100.0;
        };
        /**
         * Returns the nth possible vertex of the polygonal intersection.
         *
         * @param y The Y value of the plane.
         * @param n The zero-based index of the point. 0 <= n <= 11.
         * @return The nth possible vertex of the polygonal intersection
         * of the y plane and the RGB cube, in linear RGB coordinates, if
         * it exists. If this possible vertex lies outside of the cube,
         * [-1.0, -1.0, -1.0] is returned.
         */
        HctSolver.nthVertex = function (y, n) {
            var kR = HctSolver.Y_FROM_LINRGB[0];
            var kG = HctSolver.Y_FROM_LINRGB[1];
            var kB = HctSolver.Y_FROM_LINRGB[2];
            var coordA = n % 4 <= 1 ? 0.0 : 100.0;
            var coordB = n % 2 === 0 ? 0.0 : 100.0;
            if (n < 4) {
                var g = coordA;
                var b = coordB;
                var r = (y - g * kG - b * kB) / kR;
                if (HctSolver.isBounded(r)) {
                    return [r, g, b];
                }
                else {
                    return [-1, -1, -1];
                }
            }
            else if (n < 8) {
                var b = coordA;
                var r = coordB;
                var g = (y - r * kR - b * kB) / kG;
                if (HctSolver.isBounded(g)) {
                    return [r, g, b];
                }
                else {
                    return [-1, -1, -1];
                }
            }
            else {
                var r = coordA;
                var g = coordB;
                var b = (y - r * kR - g * kG) / kB;
                if (HctSolver.isBounded(b)) {
                    return [r, g, b];
                }
                else {
                    return [-1, -1, -1];
                }
            }
        };
        /**
         * Finds the segment containing the desired color.
         *
         * @param y The Y value of the color.
         * @param targetHue The hue of the color.
         * @return A list of two sets of linear RGB coordinates, each
         * corresponding to an endpoint of the segment containing the
         * desired color.
         */
        HctSolver.bisectToSegment = function (y, targetHue) {
            var left = [-1, -1, -1];
            var right = left;
            var leftHue = 0.0;
            var rightHue = 0.0;
            var initialized = false;
            var uncut = true;
            for (var n = 0; n < 12; n++) {
                var mid = HctSolver.nthVertex(y, n);
                if (mid[0] < 0) {
                    continue;
                }
                var midHue = HctSolver.hueOf(mid);
                if (!initialized) {
                    left = mid;
                    right = mid;
                    leftHue = midHue;
                    rightHue = midHue;
                    initialized = true;
                    continue;
                }
                if (uncut || HctSolver.areInCyclicOrder(leftHue, midHue, rightHue)) {
                    uncut = false;
                    if (HctSolver.areInCyclicOrder(leftHue, targetHue, midHue)) {
                        right = mid;
                        rightHue = midHue;
                    }
                    else {
                        left = mid;
                        leftHue = midHue;
                    }
                }
            }
            return [left, right];
        };
        HctSolver.midpoint = function (a, b) {
            return [
                (a[0] + b[0]) / 2,
                (a[1] + b[1]) / 2,
                (a[2] + b[2]) / 2,
            ];
        };
        HctSolver.criticalPlaneBelow = function (x) {
            return Math.floor(x - 0.5);
        };
        HctSolver.criticalPlaneAbove = function (x) {
            return Math.ceil(x - 0.5);
        };
        /**
         * Finds a color with the given Y and hue on the boundary of the
         * cube.
         *
         * @param y The Y value of the color.
         * @param targetHue The hue of the color.
         * @return The desired color, in linear RGB coordinates.
         */
        HctSolver.bisectToLimit = function (y, targetHue) {
            var segment = HctSolver.bisectToSegment(y, targetHue);
            var left = segment[0];
            var leftHue = HctSolver.hueOf(left);
            var right = segment[1];
            for (var axis = 0; axis < 3; axis++) {
                if (left[axis] !== right[axis]) {
                    var lPlane = -1;
                    var rPlane = 255;
                    if (left[axis] < right[axis]) {
                        lPlane = HctSolver.criticalPlaneBelow(HctSolver.trueDelinearized(left[axis]));
                        rPlane = HctSolver.criticalPlaneAbove(HctSolver.trueDelinearized(right[axis]));
                    }
                    else {
                        lPlane = HctSolver.criticalPlaneAbove(HctSolver.trueDelinearized(left[axis]));
                        rPlane = HctSolver.criticalPlaneBelow(HctSolver.trueDelinearized(right[axis]));
                    }
                    for (var i = 0; i < 8; i++) {
                        if (Math.abs(rPlane - lPlane) <= 1) {
                            break;
                        }
                        else {
                            var mPlane = Math.floor((lPlane + rPlane) / 2.0);
                            var midPlaneCoordinate = HctSolver.CRITICAL_PLANES[mPlane];
                            var mid = HctSolver.setCoordinate(left, midPlaneCoordinate, right, axis);
                            var midHue = HctSolver.hueOf(mid);
                            if (HctSolver.areInCyclicOrder(leftHue, targetHue, midHue)) {
                                right = mid;
                                rPlane = mPlane;
                            }
                            else {
                                left = mid;
                                leftHue = midHue;
                                lPlane = mPlane;
                            }
                        }
                    }
                }
            }
            return HctSolver.midpoint(left, right);
        };
        HctSolver.inverseChromaticAdaptation = function (adapted) {
            var adaptedAbs = Math.abs(adapted);
            var base = Math.max(0, 27.13 * adaptedAbs / (400.0 - adaptedAbs));
            return signum(adapted) * Math.pow(base, 1.0 / 0.42);
        };
        /**
         * Finds a color with the given hue, chroma, and Y.
         *
         * @param hueRadians The desired hue in radians.
         * @param chroma The desired chroma.
         * @param y The desired Y.
         * @return The desired color as a hexadecimal integer, if found; 0
         * otherwise.
         */
        HctSolver.findResultByJ = function (hueRadians, chroma, y) {
            // Initial estimate of j.
            var j = Math.sqrt(y) * 11.0;
            // ===========================================================
            // Operations inlined from Cam16 to avoid repeated calculation
            // ===========================================================
            var viewingConditions = ViewingConditions.DEFAULT;
            var tInnerCoeff = 1 / Math.pow(1.64 - Math.pow(0.29, viewingConditions.n), 0.73);
            var eHue = 0.25 * (Math.cos(hueRadians + 2.0) + 3.8);
            var p1 = eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb;
            var hSin = Math.sin(hueRadians);
            var hCos = Math.cos(hueRadians);
            for (var iterationRound = 0; iterationRound < 5; iterationRound++) {
                // ===========================================================
                // Operations inlined from Cam16 to avoid repeated calculation
                // ===========================================================
                var jNormalized = j / 100.0;
                var alpha = chroma === 0.0 || j === 0.0 ? 0.0 : chroma / Math.sqrt(jNormalized);
                var t = Math.pow(alpha * tInnerCoeff, 1.0 / 0.9);
                var ac = viewingConditions.aw *
                    Math.pow(jNormalized, 1.0 / viewingConditions.c / viewingConditions.z);
                var p2 = ac / viewingConditions.nbb;
                var gamma = 23.0 * (p2 + 0.305) * t /
                    (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
                var a = gamma * hCos;
                var b = gamma * hSin;
                var rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
                var gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
                var bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
                var rCScaled = HctSolver.inverseChromaticAdaptation(rA);
                var gCScaled = HctSolver.inverseChromaticAdaptation(gA);
                var bCScaled = HctSolver.inverseChromaticAdaptation(bA);
                var linrgb = matrixMultiply([rCScaled, gCScaled, bCScaled], HctSolver.LINRGB_FROM_SCALED_DISCOUNT);
                // ===========================================================
                // Operations inlined from Cam16 to avoid repeated calculation
                // ===========================================================
                if (linrgb[0] < 0 || linrgb[1] < 0 || linrgb[2] < 0) {
                    return 0;
                }
                var kR = HctSolver.Y_FROM_LINRGB[0];
                var kG = HctSolver.Y_FROM_LINRGB[1];
                var kB = HctSolver.Y_FROM_LINRGB[2];
                var fnj = kR * linrgb[0] + kG * linrgb[1] + kB * linrgb[2];
                if (fnj <= 0) {
                    return 0;
                }
                if (iterationRound === 4 || Math.abs(fnj - y) < 0.002) {
                    if (linrgb[0] > 100.01 || linrgb[1] > 100.01 || linrgb[2] > 100.01) {
                        return 0;
                    }
                    return argbFromLinrgb(linrgb);
                }
                // Iterates with Newton method,
                // Using 2 * fn(j) / j as the approximation of fn'(j)
                j = j - (fnj - y) * j / (2 * fnj);
            }
            return 0;
        };
        /**
         * Finds an sRGB color with the given hue, chroma, and L*, if
         * possible.
         *
         * @param hueDegrees The desired hue, in degrees.
         * @param chroma The desired chroma.
         * @param lstar The desired L*.
         * @return A hexadecimal representing the sRGB color. The color
         * has sufficiently close hue, chroma, and L* to the desired
         * values, if possible; otherwise, the hue and L* will be
         * sufficiently close, and chroma will be maximized.
         */
        HctSolver.solveToInt = function (hueDegrees, chroma, lstar) {
            if (chroma < 0.0001 || lstar < 0.0001 || lstar > 99.9999) {
                return argbFromLstar(lstar);
            }
            hueDegrees = sanitizeDegreesDouble(hueDegrees);
            var hueRadians = hueDegrees / 180 * Math.PI;
            var y = yFromLstar(lstar);
            var exactAnswer = HctSolver.findResultByJ(hueRadians, chroma, y);
            if (exactAnswer !== 0) {
                return exactAnswer;
            }
            var linrgb = HctSolver.bisectToLimit(y, hueRadians);
            return argbFromLinrgb(linrgb);
        };
        /**
         * Finds an sRGB color with the given hue, chroma, and L*, if
         * possible.
         *
         * @param hueDegrees The desired hue, in degrees.
         * @param chroma The desired chroma.
         * @param lstar The desired L*.
         * @return An CAM16 object representing the sRGB color. The color
         * has sufficiently close hue, chroma, and L* to the desired
         * values, if possible; otherwise, the hue and L* will be
         * sufficiently close, and chroma will be maximized.
         */
        HctSolver.solveToCam = function (hueDegrees, chroma, lstar) {
            return Cam16.fromInt(HctSolver.solveToInt(hueDegrees, chroma, lstar));
        };
        HctSolver.SCALED_DISCOUNT_FROM_LINRGB = [
            [
                0.001200833568784504,
                0.002389694492170889,
                0.0002795742885861124,
            ],
            [
                0.0005891086651375999,
                0.0029785502573438758,
                0.0003270666104008398,
            ],
            [
                0.00010146692491640572,
                0.0005364214359186694,
                0.0032979401770712076,
            ],
        ];
        HctSolver.LINRGB_FROM_SCALED_DISCOUNT = [
            [
                1373.2198709594231,
                -1100.4251190754821,
                -7.278681089101213,
            ],
            [
                -271.815969077903,
                559.6580465940733,
                -32.46047482791194,
            ],
            [
                1.9622899599665666,
                -57.173814538844006,
                308.7233197812385,
            ],
        ];
        HctSolver.Y_FROM_LINRGB = [0.2126, 0.7152, 0.0722];
        HctSolver.CRITICAL_PLANES = [
            0.015176349177441876, 0.045529047532325624, 0.07588174588720938,
            0.10623444424209313, 0.13658714259697685, 0.16693984095186062,
            0.19729253930674434, 0.2276452376616281, 0.2579979360165119,
            0.28835063437139563, 0.3188300904430532, 0.350925934958123,
            0.3848314933096426, 0.42057480301049466, 0.458183274052838,
            0.4976837250274023, 0.5391024159806381, 0.5824650784040898,
            0.6277969426914107, 0.6751227633498623, 0.7244668422128921,
            0.775853049866786, 0.829304845476233, 0.8848452951698498,
            0.942497089126609, 1.0022825574869039, 1.0642236851973577,
            1.1283421258858297, 1.1946592148522128, 1.2631959812511864,
            1.3339731595349034, 1.407011200216447, 1.4823302800086415,
            1.5599503113873272, 1.6398909516233677, 1.7221716113234105,
            1.8068114625156377, 1.8938294463134073, 1.9832442801866852,
            2.075074464868551, 2.1693382909216234, 2.2660538449872063,
            2.36523901573795, 2.4669114995532007, 2.5710888059345764,
            2.6777882626779785, 2.7870270208169257, 2.898822059350997,
            3.0131901897720907, 3.1301480604002863, 3.2497121605402226,
            3.3718988244681087, 3.4967242352587946, 3.624204428461639,
            3.754355295633311, 3.887192587735158, 4.022731918402185,
            4.160988767090289, 4.301978482107941, 4.445716283538092,
            4.592217266055746, 4.741496401646282, 4.893568542229298,
            5.048448422192488, 5.20615066083972, 5.3666897647573375,
            5.5300801301023865, 5.696336044816294, 5.865471690767354,
            6.037501145825082, 6.212438385869475, 6.390297286737924,
            6.571091626112461, 6.7548350853498045, 6.941541251256611,
            7.131223617812143, 7.323895587840543, 7.5195704746346665,
            7.7182615035334345, 7.919981813454504, 8.124744458384042,
            8.332562408825165, 8.543448553206703, 8.757415699253682,
            8.974476575321063, 9.194643831691977, 9.417930041841839,
            9.644347703669503, 9.873909240696694, 10.106627003236781,
            10.342513269534024, 10.58158024687427, 10.8238400726681,
            11.069304815507364, 11.317986476196008, 11.569896988756009,
            11.825048221409341, 12.083451977536606, 12.345119996613247,
            12.610063955123938, 12.878295467455942, 13.149826086772048,
            13.42466730586372, 13.702830557985108, 13.984327217668513,
            14.269168601521828, 14.55736596900856, 14.848930523210871,
            15.143873411576273, 15.44220572664832, 15.743938506781891,
            16.04908273684337, 16.35764934889634, 16.66964922287304,
            16.985093187232053, 17.30399201960269, 17.62635644741625,
            17.95219714852476, 18.281524751807332, 18.614349837764564,
            18.95068293910138, 19.290534541298456, 19.633915083172692,
            19.98083495742689, 20.331304511189067, 20.685334046541502,
            21.042933821039977, 21.404114048223256, 21.76888489811322,
            22.137256497705877, 22.50923893145328, 22.884842241736916,
            23.264076429332462, 23.6469514538663, 24.033477234264016,
            24.42366364919083, 24.817520537484558, 25.21505769858089,
            25.61628489293138, 26.021211842414342, 26.429848230738664,
            26.842203703840827, 27.258287870275353, 27.678110301598522,
            28.10168053274597, 28.529008062403893, 28.96010235337422,
            29.39497283293396, 29.83362889318845, 30.276079891419332,
            30.722335150426627, 31.172403958865512, 31.62629557157785,
            32.08401920991837, 32.54558406207592, 33.010999283389665,
            33.4802739966603, 33.953417292456834, 34.430438229418264,
            34.911345834551085, 35.39614910352207, 35.88485700094671,
            36.37747846067349, 36.87402238606382, 37.37449765026789,
            37.87891309649659, 38.38727753828926, 38.89959975977785,
            39.41588851594697, 39.93615253289054, 40.460400508064545,
            40.98864111053629, 41.520882981230194, 42.05713473317016,
            42.597404951718396, 43.141702194811224, 43.6900349931913,
            44.24241185063697, 44.798841244188324, 45.35933162437017,
            45.92389141541209, 46.49252901546552, 47.065252796817916,
            47.64207110610409, 48.22299226451468, 48.808024568002054,
            49.3971762874833, 49.9904556690408, 50.587870934119984,
            51.189430279724725, 51.79514187861014, 52.40501387947288,
            53.0190544071392, 53.637271562750364, 54.259673423945976,
            54.88626804504493, 55.517063457223934, 56.15206766869424,
            56.79128866487574, 57.43473440856916, 58.08241284012621,
            58.734331877617365, 59.39049941699807, 60.05092333227251,
            60.715611475655585, 61.38457167773311, 62.057811747619894,
            62.7353394731159, 63.417162620860914, 64.10328893648692,
            64.79372614476921, 65.48848194977529, 66.18756403501224,
            66.89098006357258, 67.59873767827808, 68.31084450182222,
            69.02730813691093, 69.74813616640164, 70.47333615344107,
            71.20291564160104, 71.93688215501312, 72.67524319850172,
            73.41800625771542, 74.16517879925733, 74.9167682708136,
            75.67278210128072, 76.43322770089146, 77.1981124613393,
            77.96744375590167, 78.74122893956174, 79.51947534912904,
            80.30219030335869, 81.08938110306934, 81.88105503125999,
            82.67721935322541, 83.4778813166706, 84.28304815182372,
            85.09272707154808, 85.90692527145302, 86.72564993000343,
            87.54890820862819, 88.3767072518277, 89.2090541872801,
            90.04595612594655, 90.88742016217518, 91.73345337380438,
            92.58406282226491, 93.43925555268066, 94.29903859396902,
            95.16341895893969, 96.03240364439274, 96.9059996312159,
            97.78421388448044, 98.6670533535366, 99.55452497210776,
        ];
        return HctSolver;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A color system built using CAM16 hue and chroma, and L* from
     * L*a*b*.
     *
     * Using L* creates a link between the color system, contrast, and thus
     * accessibility. Contrast ratio depends on relative luminance, or Y in the XYZ
     * color space. L*, or perceptual luminance can be calculated from Y.
     *
     * Unlike Y, L* is linear to human perception, allowing trivial creation of
     * accurate color tones.
     *
     * Unlike contrast ratio, measuring contrast in L* is linear, and simple to
     * calculate. A difference of 40 in HCT tone guarantees a contrast ratio >= 3.0,
     * and a difference of 50 guarantees a contrast ratio >= 4.5.
     */
    /**
     * HCT, hue, chroma, and tone. A color system that provides a perceptually
     * accurate color measurement system that can also accurately render what colors
     * will appear as in different lighting environments.
     */
    var Hct = /** @class */ (function () {
        function Hct(argb) {
            this.argb = argb;
            var cam = Cam16.fromInt(argb);
            this.internalHue = cam.hue;
            this.internalChroma = cam.chroma;
            this.internalTone = lstarFromArgb(argb);
            this.argb = argb;
        }
        Hct.from = function (hue, chroma, tone) {
            return new Hct(HctSolver.solveToInt(hue, chroma, tone));
        };
        /**
         * @param argb ARGB representation of a color.
         * @return HCT representation of a color in default viewing conditions
         */
        Hct.fromInt = function (argb) {
            return new Hct(argb);
        };
        Hct.prototype.toInt = function () {
            return this.argb;
        };
        Object.defineProperty(Hct.prototype, "hue", {
            /**
             * A number, in degrees, representing ex. red, orange, yellow, etc.
             * Ranges from 0 <= hue < 360.
             */
            get: function () {
                return this.internalHue;
            },
            /**
             * @param newHue 0 <= newHue < 360; invalid values are corrected.
             * Chroma may decrease because chroma has a different maximum for any given
             * hue and tone.
             */
            set: function (newHue) {
                this.setInternalState(HctSolver.solveToInt(newHue, this.internalChroma, this.internalTone));
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Hct.prototype, "chroma", {
            get: function () {
                return this.internalChroma;
            },
            /**
             * @param newChroma 0 <= newChroma < ?
             * Chroma may decrease because chroma has a different maximum for any given
             * hue and tone.
             */
            set: function (newChroma) {
                this.setInternalState(HctSolver.solveToInt(this.internalHue, newChroma, this.internalTone));
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Hct.prototype, "tone", {
            /** Lightness. Ranges from 0 to 100. */
            get: function () {
                return this.internalTone;
            },
            /**
             * @param newTone 0 <= newTone <= 100; invalid valids are corrected.
             * Chroma may decrease because chroma has a different maximum for any given
             * hue and tone.
             */
            set: function (newTone) {
                this.setInternalState(HctSolver.solveToInt(this.internalHue, this.internalChroma, newTone));
            },
            enumerable: false,
            configurable: true
        });
        /** Sets a property of the Hct object. */
        Hct.prototype.setValue = function (propertyName, value) {
            this[propertyName] = value;
        };
        Hct.prototype.toString = function () {
            return "HCT(".concat(this.hue.toFixed(0), ", ").concat(this.chroma.toFixed(0), ", ").concat(this.tone.toFixed(0), ")");
        };
        Hct.isBlue = function (hue) {
            return hue >= 250 && hue < 270;
        };
        Hct.isYellow = function (hue) {
            return hue >= 105 && hue < 125;
        };
        Hct.isCyan = function (hue) {
            return hue >= 170 && hue < 207;
        };
        Hct.prototype.setInternalState = function (argb) {
            var cam = Cam16.fromInt(argb);
            this.internalHue = cam.hue;
            this.internalChroma = cam.chroma;
            this.internalTone = lstarFromArgb(argb);
            this.argb = argb;
        };
        /**
         * Translates a color into different [ViewingConditions].
         *
         * Colors change appearance. They look different with lights on versus off,
         * the same color, as in hex code, on white looks different when on black.
         * This is called color relativity, most famously explicated by Josef Albers
         * in Interaction of Color.
         *
         * In color science, color appearance models can account for this and
         * calculate the appearance of a color in different settings. HCT is based on
         * CAM16, a color appearance model, and uses it to make these calculations.
         *
         * See [ViewingConditions.make] for parameters affecting color appearance.
         */
        Hct.prototype.inViewingConditions = function (vc) {
            // 1. Use CAM16 to find XYZ coordinates of color in specified VC.
            var cam = Cam16.fromInt(this.toInt());
            var viewedInVc = cam.xyzInViewingConditions(vc);
            // 2. Create CAM16 of those XYZ coordinates in default VC.
            var recastInVc = Cam16.fromXyzInViewingConditions(viewedInVc[0], viewedInVc[1], viewedInVc[2], ViewingConditions.make());
            // 3. Create HCT from:
            // - CAM16 using default VC with XYZ coordinates in specified VC.
            // - L* converted from Y in XYZ coordinates in specified VC.
            var recastHct = Hct.from(recastInVc.hue, recastInVc.chroma, lstarFromY(viewedInVc[1]));
            return recastHct;
        };
        return Hct;
    }());

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    function validateExtendedColor(originalColor, specVersion, extendedColor) {
        if (originalColor.name !== extendedColor.name) {
            throw new Error("Attempting to extend color ".concat(originalColor.name, " with color ").concat(extendedColor.name, " of different name for spec version ").concat(specVersion, "."));
        }
        if (originalColor.isBackground !== extendedColor.isBackground) {
            throw new Error("Attempting to extend color ".concat(originalColor.name, " as a ").concat((originalColor.isBackground ?
                'background' :
                'foreground'), " with color ").concat(extendedColor.name, " as a ").concat((extendedColor.isBackground ?
                'background' :
                'foreground'), " for spec version ").concat(specVersion, "."));
        }
    }
    /**
     * Returns a new DynamicColor that is the same as the original color, but with
     * the extended dynamic color's constraints for the given spec version.
     *
     * @param originlColor The original color.
     * @param specVersion The spec version to extend.
     * @param extendedColor The color with the values to extend.
     */
    function extendSpecVersion(originlColor, specVersion, extendedColor) {
        validateExtendedColor(originlColor, specVersion, extendedColor);
        return DynamicColor.fromPalette({
            name: originlColor.name,
            palette: function (s) { return s.specVersion === specVersion ? extendedColor.palette(s) :
                originlColor.palette(s); },
            tone: function (s) { return s.specVersion === specVersion ? extendedColor.tone(s) :
                originlColor.tone(s); },
            isBackground: originlColor.isBackground,
            chromaMultiplier: function (s) {
                var chromaMultiplier = s.specVersion === specVersion ?
                    extendedColor.chromaMultiplier :
                    originlColor.chromaMultiplier;
                return chromaMultiplier !== undefined ? chromaMultiplier(s) : 1;
            },
            background: function (s) {
                var background = s.specVersion === specVersion ?
                    extendedColor.background :
                    originlColor.background;
                return background !== undefined ? background(s) : undefined;
            },
            secondBackground: function (s) {
                var secondBackground = s.specVersion === specVersion ?
                    extendedColor.secondBackground :
                    originlColor.secondBackground;
                return secondBackground !== undefined ? secondBackground(s) : undefined;
            },
            contrastCurve: function (s) {
                var contrastCurve = s.specVersion === specVersion ?
                    extendedColor.contrastCurve :
                    originlColor.contrastCurve;
                return contrastCurve !== undefined ? contrastCurve(s) : undefined;
            },
            toneDeltaPair: function (s) {
                var toneDeltaPair = s.specVersion === specVersion ?
                    extendedColor.toneDeltaPair :
                    originlColor.toneDeltaPair;
                return toneDeltaPair !== undefined ? toneDeltaPair(s) : undefined;
            },
        });
    }
    /**
     * A color that adjusts itself based on UI state provided by DynamicScheme.
     *
     * Colors without backgrounds do not change tone when contrast changes. Colors
     * with backgrounds become closer to their background as contrast lowers, and
     * further when contrast increases.
     *
     * Prefer static constructors. They require either a hexcode, a palette and
     * tone, or a hue and chroma. Optionally, they can provide a background
     * DynamicColor.
     */
    var DynamicColor = /** @class */ (function () {
        /**
         * The base constructor for DynamicColor.
         *
         * _Strongly_ prefer using one of the convenience constructors. This class is
         * arguably too flexible to ensure it can support any scenario. Functional
         * arguments allow  overriding without risks that come with subclasses.
         *
         * For example, the default behavior of adjust tone at max contrast
         * to be at a 7.0 ratio with its background is principled and
         * matches accessibility guidance. That does not mean it's the desired
         * approach for _every_ design system, and every color pairing,
         * always, in every case.
         *
         * @param name The name of the dynamic color. Defaults to empty.
         * @param palette Function that provides a TonalPalette given DynamicScheme. A
         *     TonalPalette is defined by a hue and chroma, so this replaces the need
         *     to specify hue/chroma. By providing a tonal palette, when contrast
         *     adjustments are made, intended chroma can be preserved.
         * @param tone Function that provides a tone, given a DynamicScheme.
         * @param isBackground Whether this dynamic color is a background, with some
         *     other color as the foreground. Defaults to false.
         * @param chromaMultiplier A factor that multiplies the chroma for this color.
         * @param background The background of the dynamic color (as a function of a
         *     `DynamicScheme`), if it exists.
         * @param secondBackground A second background of the dynamic color (as a
         *     function of a `DynamicScheme`), if it exists.
         * @param contrastCurve A `ContrastCurve` object specifying how its contrast
         *     against its background should behave in various contrast levels
         *     options.
         * @param toneDeltaPair A `ToneDeltaPair` object specifying a tone delta
         *     constraint between two colors. One of them must be the color being
         *     constructed.
         */
        function DynamicColor(name, palette, tone, isBackground, chromaMultiplier, background, secondBackground, contrastCurve, toneDeltaPair) {
            this.name = name;
            this.palette = palette;
            this.tone = tone;
            this.isBackground = isBackground;
            this.chromaMultiplier = chromaMultiplier;
            this.background = background;
            this.secondBackground = secondBackground;
            this.contrastCurve = contrastCurve;
            this.toneDeltaPair = toneDeltaPair;
            this.hctCache = new Map();
            if ((!background) && secondBackground) {
                throw new Error("Color ".concat(name, " has secondBackground") +
                    "defined, but background is not defined.");
            }
            if ((!background) && contrastCurve) {
                throw new Error("Color ".concat(name, " has contrastCurve") +
                    "defined, but background is not defined.");
            }
            if (background && !contrastCurve) {
                throw new Error("Color ".concat(name, " has background") +
                    "defined, but contrastCurve is not defined.");
            }
        }
        /**
         * Create a DynamicColor defined by a TonalPalette and HCT tone.
         *
         * @param args Functions with DynamicScheme as input. Must provide a palette
         *     and tone. May provide a background DynamicColor and ToneDeltaPair.
         */
        DynamicColor.fromPalette = function (args) {
            var _a, _b, _c;
            return new DynamicColor((_a = args.name) !== null && _a !== void 0 ? _a : '', args.palette, (_b = args.tone) !== null && _b !== void 0 ? _b : DynamicColor.getInitialToneFromBackground(args.background), (_c = args.isBackground) !== null && _c !== void 0 ? _c : false, args.chromaMultiplier, args.background, args.secondBackground, args.contrastCurve, args.toneDeltaPair);
        };
        DynamicColor.getInitialToneFromBackground = function (background) {
            if (background === undefined) {
                return function (s) { return 50; };
            }
            return function (s) { return background(s) ? background(s).getTone(s) : 50; };
        };
        /**
         * Returns a deep copy of this DynamicColor.
         */
        DynamicColor.prototype.clone = function () {
            return DynamicColor.fromPalette({
                name: this.name,
                palette: this.palette,
                tone: this.tone,
                isBackground: this.isBackground,
                chromaMultiplier: this.chromaMultiplier,
                background: this.background,
                secondBackground: this.secondBackground,
                contrastCurve: this.contrastCurve,
                toneDeltaPair: this.toneDeltaPair,
            });
        };
        /**
         * Clears the cache of HCT values for this color. For testing or debugging
         * purposes.
         */
        DynamicColor.prototype.clearCache = function () {
            this.hctCache.clear();
        };
        /**
         * Returns a ARGB integer (i.e. a hex code).
         *
         * @param scheme Defines the conditions of the user interface, for example,
         *     whether or not it is dark mode or light mode, and what the desired
         *     contrast level is.
         */
        DynamicColor.prototype.getArgb = function (scheme) {
            return this.getHct(scheme).toInt();
        };
        /**
         * Returns a color, expressed in the HCT color space, that this
         * DynamicColor is under the conditions in scheme.
         *
         * @param scheme Defines the conditions of the user interface, for example,
         *     whether or not it is dark mode or light mode, and what the desired
         *     contrast level is.
         */
        DynamicColor.prototype.getHct = function (scheme) {
            var cachedAnswer = this.hctCache.get(scheme);
            if (cachedAnswer != null) {
                return cachedAnswer;
            }
            var answer = getSpec$1(scheme.specVersion).getHct(scheme, this);
            if (this.hctCache.size > 4) {
                this.hctCache.clear();
            }
            this.hctCache.set(scheme, answer);
            return answer;
        };
        /**
         * Returns a tone, T in the HCT color space, that this DynamicColor is under
         * the conditions in scheme.
         *
         * @param scheme Defines the conditions of the user interface, for example,
         *     whether or not it is dark mode or light mode, and what the desired
         *     contrast level is.
         */
        DynamicColor.prototype.getTone = function (scheme) {
            return getSpec$1(scheme.specVersion).getTone(scheme, this);
        };
        /**
         * Given a background tone, finds a foreground tone, while ensuring they reach
         * a contrast ratio that is as close to [ratio] as possible.
         *
         * @param bgTone Tone in HCT. Range is 0 to 100, undefined behavior when it
         *     falls outside that range.
         * @param ratio The contrast ratio desired between bgTone and the return
         *     value.
         */
        DynamicColor.foregroundTone = function (bgTone, ratio) {
            var lighterTone = Contrast.lighterUnsafe(bgTone, ratio);
            var darkerTone = Contrast.darkerUnsafe(bgTone, ratio);
            var lighterRatio = Contrast.ratioOfTones(lighterTone, bgTone);
            var darkerRatio = Contrast.ratioOfTones(darkerTone, bgTone);
            var preferLighter = DynamicColor.tonePrefersLightForeground(bgTone);
            if (preferLighter) {
                // This handles an edge case where the initial contrast ratio is high
                // (ex. 13.0), and the ratio passed to the function is that high
                // ratio, and both the lighter and darker ratio fails to pass that
                // ratio.
                //
                // This was observed with Tonal Spot's On Primary Container turning
                // black momentarily between high and max contrast in light mode. PC's
                // standard tone was T90, OPC's was T10, it was light mode, and the
                // contrast value was 0.6568521221032331.
                var negligibleDifference = Math.abs(lighterRatio - darkerRatio) < 0.1 &&
                    lighterRatio < ratio && darkerRatio < ratio;
                return lighterRatio >= ratio || lighterRatio >= darkerRatio ||
                    negligibleDifference ?
                    lighterTone :
                    darkerTone;
            }
            else {
                return darkerRatio >= ratio || darkerRatio >= lighterRatio ? darkerTone :
                    lighterTone;
            }
        };
        /**
         * Returns whether [tone] prefers a light foreground.
         *
         * People prefer white foregrounds on ~T60-70. Observed over time, and also
         * by Andrew Somers during research for APCA.
         *
         * T60 used as to create the smallest discontinuity possible when skipping
         * down to T49 in order to ensure light foregrounds.
         * Since `tertiaryContainer` in dark monochrome scheme requires a tone of
         * 60, it should not be adjusted. Therefore, 60 is excluded here.
         */
        DynamicColor.tonePrefersLightForeground = function (tone) {
            return Math.round(tone) < 60.0;
        };
        /**
         * Returns whether [tone] can reach a contrast ratio of 4.5 with a lighter
         * color.
         */
        DynamicColor.toneAllowsLightForeground = function (tone) {
            return Math.round(tone) <= 49.0;
        };
        /**
         * Adjusts a tone such that white has 4.5 contrast, if the tone is
         * reasonably close to supporting it.
         */
        DynamicColor.enableLightForeground = function (tone) {
            if (DynamicColor.tonePrefersLightForeground(tone) &&
                !DynamicColor.toneAllowsLightForeground(tone)) {
                return 49.0;
            }
            return tone;
        };
        return DynamicColor;
    }());
    /**
     * A delegate for the color calculation of a DynamicScheme in the 2021 spec.
     */
    var ColorCalculationDelegateImpl2021 = /** @class */ (function () {
        function ColorCalculationDelegateImpl2021() {
        }
        ColorCalculationDelegateImpl2021.prototype.getHct = function (scheme, color) {
            var tone = color.getTone(scheme);
            var palette = color.palette(scheme);
            return palette.getHct(tone);
        };
        ColorCalculationDelegateImpl2021.prototype.getTone = function (scheme, color) {
            var decreasingContrast = scheme.contrastLevel < 0;
            var toneDeltaPair = color.toneDeltaPair ? color.toneDeltaPair(scheme) : undefined;
            // Case 1: dual foreground, pair of colors with delta constraint.
            if (toneDeltaPair) {
                var roleA = toneDeltaPair.roleA;
                var roleB = toneDeltaPair.roleB;
                var delta = toneDeltaPair.delta;
                var polarity = toneDeltaPair.polarity;
                var stayTogether = toneDeltaPair.stayTogether;
                var aIsNearer = (polarity === 'nearer' ||
                    (polarity === 'lighter' && !scheme.isDark) ||
                    (polarity === 'darker' && scheme.isDark));
                var nearer = aIsNearer ? roleA : roleB;
                var farther = aIsNearer ? roleB : roleA;
                var amNearer = color.name === nearer.name;
                var expansionDir = scheme.isDark ? 1 : -1;
                var nTone = nearer.tone(scheme);
                var fTone = farther.tone(scheme);
                // 1st round: solve to min for each, if background and contrast curve
                // are defined.
                if (color.background && nearer.contrastCurve && farther.contrastCurve) {
                    var bg = color.background(scheme);
                    var nContrastCurve = nearer.contrastCurve(scheme);
                    var fContrastCurve = farther.contrastCurve(scheme);
                    if (bg && nContrastCurve && fContrastCurve) {
                        var bgTone = bg.getTone(scheme);
                        var nContrast = nContrastCurve.get(scheme.contrastLevel);
                        var fContrast = fContrastCurve.get(scheme.contrastLevel);
                        // If a color is good enough, it is not adjusted.
                        // Initial and adjusted tones for `nearer`
                        if (Contrast.ratioOfTones(bgTone, nTone) < nContrast) {
                            nTone = DynamicColor.foregroundTone(bgTone, nContrast);
                        }
                        // Initial and adjusted tones for `farther`
                        if (Contrast.ratioOfTones(bgTone, fTone) < fContrast) {
                            fTone = DynamicColor.foregroundTone(bgTone, fContrast);
                        }
                        if (decreasingContrast) {
                            // If decreasing contrast, adjust color to the "bare minimum"
                            // that satisfies contrast.
                            nTone = DynamicColor.foregroundTone(bgTone, nContrast);
                            fTone = DynamicColor.foregroundTone(bgTone, fContrast);
                        }
                    }
                }
                if ((fTone - nTone) * expansionDir < delta) {
                    // 2nd round: expand farther to match delta, if contrast is not
                    // satisfied.
                    fTone = clampDouble(0, 100, nTone + delta * expansionDir);
                    if ((fTone - nTone) * expansionDir >= delta) ;
                    else {
                        // 3rd round: contract nearer to match delta.
                        nTone = clampDouble(0, 100, fTone - delta * expansionDir);
                    }
                }
                // Avoids the 50-59 awkward zone.
                if (50 <= nTone && nTone < 60) {
                    // If `nearer` is in the awkward zone, move it away, together with
                    // `farther`.
                    if (expansionDir > 0) {
                        nTone = 60;
                        fTone = Math.max(fTone, nTone + delta * expansionDir);
                    }
                    else {
                        nTone = 49;
                        fTone = Math.min(fTone, nTone + delta * expansionDir);
                    }
                }
                else if (50 <= fTone && fTone < 60) {
                    if (stayTogether) {
                        // Fixes both, to avoid two colors on opposite sides of the "awkward
                        // zone".
                        if (expansionDir > 0) {
                            nTone = 60;
                            fTone = Math.max(fTone, nTone + delta * expansionDir);
                        }
                        else {
                            nTone = 49;
                            fTone = Math.min(fTone, nTone + delta * expansionDir);
                        }
                    }
                    else {
                        // Not required to stay together; fixes just one.
                        if (expansionDir > 0) {
                            fTone = 60;
                        }
                        else {
                            fTone = 49;
                        }
                    }
                }
                // Returns `nTone` if this color is `nearer`, otherwise `fTone`.
                return amNearer ? nTone : fTone;
            }
            else {
                // Case 2: No contrast pair; just solve for itself.
                var answer = color.tone(scheme);
                if (color.background == undefined ||
                    color.background(scheme) === undefined ||
                    color.contrastCurve == undefined ||
                    color.contrastCurve(scheme) === undefined) {
                    return answer; // No adjustment for colors with no background.
                }
                var bgTone = color.background(scheme).getTone(scheme);
                var desiredRatio = color.contrastCurve(scheme).get(scheme.contrastLevel);
                if (Contrast.ratioOfTones(bgTone, answer) >= desiredRatio) ;
                else {
                    // Rough improvement.
                    answer = DynamicColor.foregroundTone(bgTone, desiredRatio);
                }
                if (decreasingContrast) {
                    answer = DynamicColor.foregroundTone(bgTone, desiredRatio);
                }
                if (color.isBackground && 50 <= answer && answer < 60) {
                    // Must adjust
                    if (Contrast.ratioOfTones(49, bgTone) >= desiredRatio) {
                        answer = 49;
                    }
                    else {
                        answer = 60;
                    }
                }
                if (color.secondBackground == undefined ||
                    color.secondBackground(scheme) === undefined) {
                    return answer;
                }
                // Case 3: Adjust for dual backgrounds.
                var _a = __read([color.background, color.secondBackground], 2), bg1 = _a[0], bg2 = _a[1];
                var _b = __read([bg1(scheme).getTone(scheme), bg2(scheme).getTone(scheme)], 2), bgTone1 = _b[0], bgTone2 = _b[1];
                var _c = __read([Math.max(bgTone1, bgTone2), Math.min(bgTone1, bgTone2)], 2), upper = _c[0], lower = _c[1];
                if (Contrast.ratioOfTones(upper, answer) >= desiredRatio &&
                    Contrast.ratioOfTones(lower, answer) >= desiredRatio) {
                    return answer;
                }
                // The darkest light tone that satisfies the desired ratio,
                // or -1 if such ratio cannot be reached.
                var lightOption = Contrast.lighter(upper, desiredRatio);
                // The lightest dark tone that satisfies the desired ratio,
                // or -1 if such ratio cannot be reached.
                var darkOption = Contrast.darker(lower, desiredRatio);
                // Tones suitable for the foreground.
                var availables = [];
                if (lightOption !== -1)
                    availables.push(lightOption);
                if (darkOption !== -1)
                    availables.push(darkOption);
                var prefersLight = DynamicColor.tonePrefersLightForeground(bgTone1) ||
                    DynamicColor.tonePrefersLightForeground(bgTone2);
                if (prefersLight) {
                    return (lightOption < 0) ? 100 : lightOption;
                }
                if (availables.length === 1) {
                    return availables[0];
                }
                return (darkOption < 0) ? 0 : darkOption;
            }
        };
        return ColorCalculationDelegateImpl2021;
    }());
    /**
     * A delegate for the color calculation of a DynamicScheme in the 2025 spec.
     */
    var ColorCalculationDelegateImpl2025 = /** @class */ (function () {
        function ColorCalculationDelegateImpl2025() {
        }
        ColorCalculationDelegateImpl2025.prototype.getHct = function (scheme, color) {
            var palette = color.palette(scheme);
            var tone = color.getTone(scheme);
            var hue = palette.hue;
            var chroma = palette.chroma *
                (color.chromaMultiplier ? color.chromaMultiplier(scheme) : 1);
            return Hct.from(hue, chroma, tone);
        };
        ColorCalculationDelegateImpl2025.prototype.getTone = function (scheme, color) {
            var toneDeltaPair = color.toneDeltaPair ? color.toneDeltaPair(scheme) : undefined;
            // Case 0: tone delta constraint.
            if (toneDeltaPair) {
                var roleA = toneDeltaPair.roleA;
                var roleB = toneDeltaPair.roleB;
                var polarity = toneDeltaPair.polarity;
                var constraint = toneDeltaPair.constraint;
                var absoluteDelta = polarity === 'darker' ||
                    (polarity === 'relative_lighter' && scheme.isDark) ||
                    (polarity === 'relative_darker' && !scheme.isDark) ?
                    -toneDeltaPair.delta :
                    toneDeltaPair.delta;
                var amRoleA = color.name === roleA.name;
                var selfRole = amRoleA ? roleA : roleB;
                var refRole = amRoleA ? roleB : roleA;
                var selfTone = selfRole.tone(scheme);
                var refTone = refRole.getTone(scheme);
                var relativeDelta = absoluteDelta * (amRoleA ? 1 : -1);
                if (constraint === 'exact') {
                    selfTone = clampDouble(0, 100, refTone + relativeDelta);
                }
                else if (constraint === 'nearer') {
                    if (relativeDelta > 0) {
                        selfTone = clampDouble(0, 100, clampDouble(refTone, refTone + relativeDelta, selfTone));
                    }
                    else {
                        selfTone = clampDouble(0, 100, clampDouble(refTone + relativeDelta, refTone, selfTone));
                    }
                }
                else if (constraint === 'farther') {
                    if (relativeDelta > 0) {
                        selfTone = clampDouble(refTone + relativeDelta, 100, selfTone);
                    }
                    else {
                        selfTone = clampDouble(0, refTone + relativeDelta, selfTone);
                    }
                }
                if (color.background && color.contrastCurve) {
                    var background = color.background(scheme);
                    var contrastCurve = color.contrastCurve(scheme);
                    if (background && contrastCurve) {
                        // Adjust the tones for contrast, if background and contrast curve
                        // are defined.
                        var bgTone = background.getTone(scheme);
                        var selfContrast = contrastCurve.get(scheme.contrastLevel);
                        selfTone = Contrast.ratioOfTones(bgTone, selfTone) >= selfContrast &&
                            scheme.contrastLevel >= 0 ?
                            selfTone :
                            DynamicColor.foregroundTone(bgTone, selfContrast);
                    }
                }
                // This can avoid the awkward tones for background colors including the
                // access fixed colors. Accent fixed dim colors should not be adjusted.
                if (color.isBackground && !color.name.endsWith('_fixed_dim')) {
                    if (selfTone >= 57) {
                        selfTone = clampDouble(65, 100, selfTone);
                    }
                    else {
                        selfTone = clampDouble(0, 49, selfTone);
                    }
                }
                return selfTone;
            }
            else {
                // Case 1: No tone delta pair; just solve for itself.
                var answer = color.tone(scheme);
                if (color.background == undefined ||
                    color.background(scheme) === undefined ||
                    color.contrastCurve == undefined ||
                    color.contrastCurve(scheme) === undefined) {
                    return answer; // No adjustment for colors with no background.
                }
                var bgTone = color.background(scheme).getTone(scheme);
                var desiredRatio = color.contrastCurve(scheme).get(scheme.contrastLevel);
                // Recalculate the tone from desired contrast ratio if the current
                // contrast ratio is not enough or desired contrast level is decreasing
                // (<0).
                answer = Contrast.ratioOfTones(bgTone, answer) >= desiredRatio &&
                    scheme.contrastLevel >= 0 ?
                    answer :
                    DynamicColor.foregroundTone(bgTone, desiredRatio);
                // This can avoid the awkward tones for background colors including the
                // access fixed colors. Accent fixed dim colors should not be adjusted.
                if (color.isBackground && !color.name.endsWith('_fixed_dim')) {
                    if (answer >= 57) {
                        answer = clampDouble(65, 100, answer);
                    }
                    else {
                        answer = clampDouble(0, 49, answer);
                    }
                }
                if (color.secondBackground == undefined ||
                    color.secondBackground(scheme) === undefined) {
                    return answer;
                }
                // Case 2: Adjust for dual backgrounds.
                var _a = __read([color.background, color.secondBackground], 2), bg1 = _a[0], bg2 = _a[1];
                var _b = __read([bg1(scheme).getTone(scheme), bg2(scheme).getTone(scheme)], 2), bgTone1 = _b[0], bgTone2 = _b[1];
                var _c = __read([Math.max(bgTone1, bgTone2), Math.min(bgTone1, bgTone2)], 2), upper = _c[0], lower = _c[1];
                if (Contrast.ratioOfTones(upper, answer) >= desiredRatio &&
                    Contrast.ratioOfTones(lower, answer) >= desiredRatio) {
                    return answer;
                }
                // The darkest light tone that satisfies the desired ratio,
                // or -1 if such ratio cannot be reached.
                var lightOption = Contrast.lighter(upper, desiredRatio);
                // The lightest dark tone that satisfies the desired ratio,
                // or -1 if such ratio cannot be reached.
                var darkOption = Contrast.darker(lower, desiredRatio);
                // Tones suitable for the foreground.
                var availables = [];
                if (lightOption !== -1)
                    availables.push(lightOption);
                if (darkOption !== -1)
                    availables.push(darkOption);
                var prefersLight = DynamicColor.tonePrefersLightForeground(bgTone1) ||
                    DynamicColor.tonePrefersLightForeground(bgTone2);
                if (prefersLight) {
                    return (lightOption < 0) ? 100 : lightOption;
                }
                if (availables.length === 1) {
                    return availables[0];
                }
                return (darkOption < 0) ? 0 : darkOption;
            }
        };
        return ColorCalculationDelegateImpl2025;
    }());
    var spec2021$1 = new ColorCalculationDelegateImpl2021();
    var spec2025$1 = new ColorCalculationDelegateImpl2025();
    /**
     * Returns the ColorCalculationDelegate for the given spec version.
     */
    function getSpec$1(specVersion) {
        return specVersion === '2025' ? spec2025$1 : spec2021$1;
    }

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable:class-as-namespace
    /**
     * Check and/or fix universally disliked colors.
     * Color science studies of color preference indicate universal distaste for
     * dark yellow-greens, and also show this is correlated to distate for
     * biological waste and rotting food.
     *
     * See Palmer and Schloss, 2010 or Schloss and Palmer's Chapter 21 in Handbook
     * of Color Psychology (2015).
     */
    var DislikeAnalyzer = /** @class */ (function () {
        function DislikeAnalyzer() {
        }
        /**
         * Returns true if a color is disliked.
         *
         * @param hct A color to be judged.
         * @return Whether the color is disliked.
         *
         * Disliked is defined as a dark yellow-green that is not neutral.
         */
        DislikeAnalyzer.isDisliked = function (hct) {
            var huePasses = Math.round(hct.hue) >= 90.0 && Math.round(hct.hue) <= 111.0;
            var chromaPasses = Math.round(hct.chroma) > 16.0;
            var tonePasses = Math.round(hct.tone) < 65.0;
            return huePasses && chromaPasses && tonePasses;
        };
        /**
         * If a color is disliked, lighten it to make it likable.
         *
         * @param hct A color to be judged.
         * @return A new color if the original color is disliked, or the original
         *   color if it is acceptable.
         */
        DislikeAnalyzer.fixIfDisliked = function (hct) {
            if (DislikeAnalyzer.isDisliked(hct)) {
                return Hct.from(hct.hue, hct.chroma, 70.0);
            }
            return hct;
        };
        return DislikeAnalyzer;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     *  A convenience class for retrieving colors that are constant in hue and
     *  chroma, but vary in tone.
     */
    var TonalPalette = /** @class */ (function () {
        function TonalPalette(hue, chroma, keyColor) {
            this.hue = hue;
            this.chroma = chroma;
            this.keyColor = keyColor;
            this.cache = new Map();
        }
        /**
         * @param argb ARGB representation of a color
         * @return Tones matching that color's hue and chroma.
         */
        TonalPalette.fromInt = function (argb) {
            var hct = Hct.fromInt(argb);
            return TonalPalette.fromHct(hct);
        };
        /**
         * @param hct Hct
         * @return Tones matching that color's hue and chroma.
         */
        TonalPalette.fromHct = function (hct) {
            return new TonalPalette(hct.hue, hct.chroma, hct);
        };
        /**
         * @param hue HCT hue
         * @param chroma HCT chroma
         * @return Tones matching hue and chroma.
         */
        TonalPalette.fromHueAndChroma = function (hue, chroma) {
            var keyColor = new KeyColor(hue, chroma).create();
            return new TonalPalette(hue, chroma, keyColor);
        };
        /**
         * @param tone HCT tone, measured from 0 to 100.
         * @return ARGB representation of a color with that tone.
         */
        TonalPalette.prototype.tone = function (tone) {
            var argb = this.cache.get(tone);
            if (argb === undefined) {
                if (tone == 99 && Hct.isYellow(this.hue)) {
                    argb = this.averageArgb(this.tone(98), this.tone(100));
                }
                else {
                    argb = Hct.from(this.hue, this.chroma, tone).toInt();
                }
                this.cache.set(tone, argb);
            }
            return argb;
        };
        /**
         * @param tone HCT tone.
         * @return HCT representation of a color with that tone.
         */
        TonalPalette.prototype.getHct = function (tone) {
            return Hct.fromInt(this.tone(tone));
        };
        TonalPalette.prototype.averageArgb = function (argb1, argb2) {
            var red1 = (argb1 >>> 16) & 0xff;
            var green1 = (argb1 >>> 8) & 0xff;
            var blue1 = argb1 & 0xff;
            var red2 = (argb2 >>> 16) & 0xff;
            var green2 = (argb2 >>> 8) & 0xff;
            var blue2 = argb2 & 0xff;
            var red = Math.round((red1 + red2) / 2);
            var green = Math.round((green1 + green2) / 2);
            var blue = Math.round((blue1 + blue2) / 2);
            return (255 << 24 | (red & 255) << 16 | (green & 255) << 8 |
                (blue & 255)) >>>
                0;
        };
        return TonalPalette;
    }());
    /**
     * Key color is a color that represents the hue and chroma of a tonal palette
     */
    var KeyColor = /** @class */ (function () {
        function KeyColor(hue, requestedChroma) {
            this.hue = hue;
            this.requestedChroma = requestedChroma;
            // Cache that maps tone to max chroma to avoid duplicated HCT calculation.
            this.chromaCache = new Map();
            this.maxChromaValue = 200.0;
        }
        /**
         * Creates a key color from a [hue] and a [chroma].
         * The key color is the first tone, starting from T50, matching the given hue
         * and chroma.
         *
         * @return Key color [Hct]
         */
        KeyColor.prototype.create = function () {
            // Pivot around T50 because T50 has the most chroma available, on
            // average. Thus it is most likely to have a direct answer.
            var pivotTone = 50;
            var toneStepSize = 1;
            // Epsilon to accept values slightly higher than the requested chroma.
            var epsilon = 0.01;
            // Binary search to find the tone that can provide a chroma that is closest
            // to the requested chroma.
            var lowerTone = 0;
            var upperTone = 100;
            while (lowerTone < upperTone) {
                var midTone = Math.floor((lowerTone + upperTone) / 2);
                var isAscending = this.maxChroma(midTone) < this.maxChroma(midTone + toneStepSize);
                var sufficientChroma = this.maxChroma(midTone) >= this.requestedChroma - epsilon;
                if (sufficientChroma) {
                    // Either range [lowerTone, midTone] or [midTone, upperTone] has
                    // the answer, so search in the range that is closer the pivot tone.
                    if (Math.abs(lowerTone - pivotTone) < Math.abs(upperTone - pivotTone)) {
                        upperTone = midTone;
                    }
                    else {
                        if (lowerTone === midTone) {
                            return Hct.from(this.hue, this.requestedChroma, lowerTone);
                        }
                        lowerTone = midTone;
                    }
                }
                else {
                    // As there is no sufficient chroma in the midTone, follow the direction
                    // to the chroma peak.
                    if (isAscending) {
                        lowerTone = midTone + toneStepSize;
                    }
                    else {
                        // Keep midTone for potential chroma peak.
                        upperTone = midTone;
                    }
                }
            }
            return Hct.from(this.hue, this.requestedChroma, lowerTone);
        };
        // Find the maximum chroma for a given tone
        KeyColor.prototype.maxChroma = function (tone) {
            if (this.chromaCache.has(tone)) {
                return this.chromaCache.get(tone);
            }
            var chroma = Hct.from(this.hue, this.maxChromaValue, tone).chroma;
            this.chromaCache.set(tone, chroma);
            return chroma;
        };
        return KeyColor;
    }());

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Design utilities using color temperature theory.
     *
     * Analogous colors, complementary color, and cache to efficiently, lazily,
     * generate data for calculations when needed.
     */
    var TemperatureCache = /** @class */ (function () {
        function TemperatureCache(input) {
            this.input = input;
            this.hctsByTempCache = [];
            this.hctsByHueCache = [];
            this.tempsByHctCache = new Map();
            this.inputRelativeTemperatureCache = -1;
            this.complementCache = null;
        }
        Object.defineProperty(TemperatureCache.prototype, "hctsByTemp", {
            get: function () {
                if (this.hctsByTempCache.length > 0) {
                    return this.hctsByTempCache;
                }
                var hcts = this.hctsByHue.concat([this.input]);
                var temperaturesByHct = this.tempsByHct;
                hcts.sort(function (a, b) { return temperaturesByHct.get(a) - temperaturesByHct.get(b); });
                this.hctsByTempCache = hcts;
                return hcts;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(TemperatureCache.prototype, "warmest", {
            get: function () {
                return this.hctsByTemp[this.hctsByTemp.length - 1];
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(TemperatureCache.prototype, "coldest", {
            get: function () {
                return this.hctsByTemp[0];
            },
            enumerable: false,
            configurable: true
        });
        /**
         * A set of colors with differing hues, equidistant in temperature.
         *
         * In art, this is usually described as a set of 5 colors on a color wheel
         * divided into 12 sections. This method allows provision of either of those
         * values.
         *
         * Behavior is undefined when [count] or [divisions] is 0.
         * When divisions < count, colors repeat.
         *
         * [count] The number of colors to return, includes the input color.
         * [divisions] The number of divisions on the color wheel.
         */
        TemperatureCache.prototype.analogous = function (count, divisions) {
            if (count === void 0) { count = 5; }
            if (divisions === void 0) { divisions = 12; }
            var startHue = Math.round(this.input.hue);
            var startHct = this.hctsByHue[startHue];
            var lastTemp = this.relativeTemperature(startHct);
            var allColors = [startHct];
            var absoluteTotalTempDelta = 0.0;
            for (var i = 0; i < 360; i++) {
                var hue = sanitizeDegreesInt(startHue + i);
                var hct = this.hctsByHue[hue];
                var temp = this.relativeTemperature(hct);
                var tempDelta = Math.abs(temp - lastTemp);
                lastTemp = temp;
                absoluteTotalTempDelta += tempDelta;
            }
            var hueAddend = 1;
            var tempStep = absoluteTotalTempDelta / divisions;
            var totalTempDelta = 0.0;
            lastTemp = this.relativeTemperature(startHct);
            while (allColors.length < divisions) {
                var hue = sanitizeDegreesInt(startHue + hueAddend);
                var hct = this.hctsByHue[hue];
                var temp = this.relativeTemperature(hct);
                var tempDelta = Math.abs(temp - lastTemp);
                totalTempDelta += tempDelta;
                var desiredTotalTempDeltaForIndex = allColors.length * tempStep;
                var indexSatisfied = totalTempDelta >= desiredTotalTempDeltaForIndex;
                var indexAddend = 1;
                // Keep adding this hue to the answers until its temperature is
                // insufficient. This ensures consistent behavior when there aren't
                // [divisions] discrete steps between 0 and 360 in hue with [tempStep]
                // delta in temperature between them.
                //
                // For example, white and black have no analogues: there are no other
                // colors at T100/T0. Therefore, they should just be added to the array
                // as answers.
                while (indexSatisfied && allColors.length < divisions) {
                    allColors.push(hct);
                    var desiredTotalTempDeltaForIndex_1 = ((allColors.length + indexAddend) * tempStep);
                    indexSatisfied = totalTempDelta >= desiredTotalTempDeltaForIndex_1;
                    indexAddend++;
                }
                lastTemp = temp;
                hueAddend++;
                if (hueAddend > 360) {
                    while (allColors.length < divisions) {
                        allColors.push(hct);
                    }
                    break;
                }
            }
            var answers = [this.input];
            // First, generate analogues from rotating counter-clockwise.
            var increaseHueCount = Math.floor((count - 1) / 2.0);
            for (var i = 1; i < (increaseHueCount + 1); i++) {
                var index = 0 - i;
                while (index < 0) {
                    index = allColors.length + index;
                }
                if (index >= allColors.length) {
                    index = index % allColors.length;
                }
                answers.splice(0, 0, allColors[index]);
            }
            // Second, generate analogues from rotating clockwise.
            var decreaseHueCount = count - increaseHueCount - 1;
            for (var i = 1; i < (decreaseHueCount + 1); i++) {
                var index = i;
                while (index < 0) {
                    index = allColors.length + index;
                }
                if (index >= allColors.length) {
                    index = index % allColors.length;
                }
                answers.push(allColors[index]);
            }
            return answers;
        };
        Object.defineProperty(TemperatureCache.prototype, "complement", {
            /**
             * A color that complements the input color aesthetically.
             *
             * In art, this is usually described as being across the color wheel.
             * History of this shows intent as a color that is just as cool-warm as the
             * input color is warm-cool.
             */
            get: function () {
                if (this.complementCache != null) {
                    return this.complementCache;
                }
                var coldestHue = this.coldest.hue;
                var coldestTemp = this.tempsByHct.get(this.coldest);
                var warmestHue = this.warmest.hue;
                var warmestTemp = this.tempsByHct.get(this.warmest);
                var range = warmestTemp - coldestTemp;
                var startHueIsColdestToWarmest = TemperatureCache.isBetween(this.input.hue, coldestHue, warmestHue);
                var startHue = startHueIsColdestToWarmest ? warmestHue : coldestHue;
                var endHue = startHueIsColdestToWarmest ? coldestHue : warmestHue;
                var directionOfRotation = 1.0;
                var smallestError = 1000.0;
                var answer = this.hctsByHue[Math.round(this.input.hue)];
                var complementRelativeTemp = 1.0 - this.inputRelativeTemperature;
                // Find the color in the other section, closest to the inverse percentile
                // of the input color. This is the complement.
                for (var hueAddend = 0.0; hueAddend <= 360.0; hueAddend += 1.0) {
                    var hue = sanitizeDegreesDouble(startHue + directionOfRotation * hueAddend);
                    if (!TemperatureCache.isBetween(hue, startHue, endHue)) {
                        continue;
                    }
                    var possibleAnswer = this.hctsByHue[Math.round(hue)];
                    var relativeTemp = (this.tempsByHct.get(possibleAnswer) - coldestTemp) / range;
                    var error = Math.abs(complementRelativeTemp - relativeTemp);
                    if (error < smallestError) {
                        smallestError = error;
                        answer = possibleAnswer;
                    }
                }
                this.complementCache = answer;
                return this.complementCache;
            },
            enumerable: false,
            configurable: true
        });
        /**
         * Temperature relative to all colors with the same chroma and tone.
         * Value on a scale from 0 to 1.
         */
        TemperatureCache.prototype.relativeTemperature = function (hct) {
            var range = this.tempsByHct.get(this.warmest) - this.tempsByHct.get(this.coldest);
            var differenceFromColdest = this.tempsByHct.get(hct) - this.tempsByHct.get(this.coldest);
            // Handle when there's no difference in temperature between warmest and
            // coldest: for example, at T100, only one color is available, white.
            if (range === 0.0) {
                return 0.5;
            }
            return differenceFromColdest / range;
        };
        Object.defineProperty(TemperatureCache.prototype, "inputRelativeTemperature", {
            /** Relative temperature of the input color. See [relativeTemperature]. */
            get: function () {
                if (this.inputRelativeTemperatureCache >= 0.0) {
                    return this.inputRelativeTemperatureCache;
                }
                this.inputRelativeTemperatureCache = this.relativeTemperature(this.input);
                return this.inputRelativeTemperatureCache;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(TemperatureCache.prototype, "tempsByHct", {
            /** A Map with keys of HCTs in [hctsByTemp], values of raw temperature. */
            get: function () {
                var e_1, _a;
                if (this.tempsByHctCache.size > 0) {
                    return this.tempsByHctCache;
                }
                var allHcts = this.hctsByHue.concat([this.input]);
                var temperaturesByHct = new Map();
                try {
                    for (var allHcts_1 = __values(allHcts), allHcts_1_1 = allHcts_1.next(); !allHcts_1_1.done; allHcts_1_1 = allHcts_1.next()) {
                        var e = allHcts_1_1.value;
                        temperaturesByHct.set(e, TemperatureCache.rawTemperature(e));
                    }
                }
                catch (e_1_1) { e_1 = { error: e_1_1 }; }
                finally {
                    try {
                        if (allHcts_1_1 && !allHcts_1_1.done && (_a = allHcts_1.return)) _a.call(allHcts_1);
                    }
                    finally { if (e_1) throw e_1.error; }
                }
                this.tempsByHctCache = temperaturesByHct;
                return temperaturesByHct;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(TemperatureCache.prototype, "hctsByHue", {
            /**
             * HCTs for all hues, with the same chroma/tone as the input.
             * Sorted ascending, hue 0 to 360.
             */
            get: function () {
                if (this.hctsByHueCache.length > 0) {
                    return this.hctsByHueCache;
                }
                var hcts = [];
                for (var hue = 0.0; hue <= 360.0; hue += 1.0) {
                    var colorAtHue = Hct.from(hue, this.input.chroma, this.input.tone);
                    hcts.push(colorAtHue);
                }
                this.hctsByHueCache = hcts;
                return this.hctsByHueCache;
            },
            enumerable: false,
            configurable: true
        });
        /** Determines if an angle is between two other angles, rotating clockwise. */
        TemperatureCache.isBetween = function (angle, a, b) {
            if (a < b) {
                return a <= angle && angle <= b;
            }
            return a <= angle || angle <= b;
        };
        /**
         * Value representing cool-warm factor of a color.
         * Values below 0 are considered cool, above, warm.
         *
         * Color science has researched emotion and harmony, which art uses to select
         * colors. Warm-cool is the foundation of analogous and complementary colors.
         * See:
         * - Li-Chen Ou's Chapter 19 in Handbook of Color Psychology (2015).
         * - Josef Albers' Interaction of Color chapters 19 and 21.
         *
         * Implementation of Ou, Woodcock and Wright's algorithm, which uses
         * L*a*b* / LCH color space.
         * Return value has these properties:
         * - Values below 0 are cool, above 0 are warm.
         * - Lower bound: -0.52 - (chroma ^ 1.07 / 20). L*a*b* chroma is infinite.
         *   Assuming max of 130 chroma, -9.66.
         * - Upper bound: -0.52 + (chroma ^ 1.07 / 20). L*a*b* chroma is infinite.
         *   Assuming max of 130 chroma, 8.61.
         */
        TemperatureCache.rawTemperature = function (color) {
            var lab = labFromArgb(color.toInt());
            var hue = sanitizeDegreesDouble(Math.atan2(lab[2], lab[1]) * 180.0 / Math.PI);
            var chroma = Math.sqrt((lab[1] * lab[1]) + (lab[2] * lab[2]));
            var temperature = -0.5 +
                0.02 * Math.pow(chroma, 1.07) *
                    Math.cos(sanitizeDegreesDouble(hue - 50.0) * Math.PI / 180.0);
            return temperature;
        };
        return TemperatureCache;
    }());

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A class containing a value that changes with the contrast level.
     *
     * Usually represents the contrast requirements for a dynamic color on its
     * background. The four values correspond to values for contrast levels -1.0,
     * 0.0, 0.5, and 1.0, respectively.
     */
    var ContrastCurve = /** @class */ (function () {
        /**
         * Creates a `ContrastCurve` object.
         *
         * @param low Value for contrast level -1.0
         * @param normal Value for contrast level 0.0
         * @param medium Value for contrast level 0.5
         * @param high Value for contrast level 1.0
         */
        function ContrastCurve(low, normal, medium, high) {
            this.low = low;
            this.normal = normal;
            this.medium = medium;
            this.high = high;
        }
        /**
         * Returns the value at a given contrast level.
         *
         * @param contrastLevel The contrast level. 0.0 is the default (normal); -1.0
         *     is the lowest; 1.0 is the highest.
         * @return The value. For contrast ratios, a number between 1.0 and 21.0.
         */
        ContrastCurve.prototype.get = function (contrastLevel) {
            if (contrastLevel <= -1) {
                return this.low;
            }
            else if (contrastLevel < 0.0) {
                return lerp(this.low, this.normal, (contrastLevel - (-1)) / 1);
            }
            else if (contrastLevel < 0.5) {
                return lerp(this.normal, this.medium, (contrastLevel - 0) / 0.5);
            }
            else if (contrastLevel < 1.0) {
                return lerp(this.medium, this.high, (contrastLevel - 0.5) / 0.5);
            }
            else {
                return this.high;
            }
        };
        return ContrastCurve;
    }());

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Documents a constraint between two DynamicColors, in which their tones must
     * have a certain distance from each other.
     *
     * Prefer a DynamicColor with a background, this is for special cases when
     * designers want tonal distance, literally contrast, between two colors that
     * don't have a background / foreground relationship or a contrast guarantee.
     */
    var ToneDeltaPair = /** @class */ (function () {
        /**
         * Documents a constraint in tone distance between two DynamicColors.
         *
         * The polarity is an adjective that describes "A", compared to "B".
         *
         * For instance, ToneDeltaPair(A, B, 15, 'darker', 'exact') states that
         * A's tone should be exactly 15 darker than B's.
         *
         * 'relative_darker' and 'relative_lighter' describes the tone adjustment
         * relative to the surface color trend (white in light mode; black in dark
         * mode). For instance, ToneDeltaPair(A, B, 10, 'relative_lighter',
         * 'farther') states that A should be at least 10 lighter than B in light
         * mode, and at least 10 darker than B in dark mode.
         *
         * @param roleA The first role in a pair.
         * @param roleB The second role in a pair.
         * @param delta Required difference between tones. Absolute value, negative
         * values have undefined behavior.
         * @param polarity The relative relation between tones of roleA and roleB,
         * as described above.
         * @param constraint How to fulfill the tone delta pair constraint.
         * @param stayTogether Whether these two roles should stay on the same side
         * of the "awkward zone" (T50-59). This is necessary for certain cases where
         * one role has two backgrounds.
         */
        function ToneDeltaPair(roleA, roleB, delta, polarity, stayTogether, constraint) {
            this.roleA = roleA;
            this.roleB = roleB;
            this.delta = delta;
            this.polarity = polarity;
            this.stayTogether = stayTogether;
            this.constraint = constraint;
            this.constraint = constraint !== null && constraint !== void 0 ? constraint : 'exact';
        }
        return ToneDeltaPair;
    }());

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Set of themes supported by Dynamic Color.
     * Instantiate the corresponding subclass, ex. SchemeTonalSpot, to create
     * colors corresponding to the theme.
     */
    exports.Variant = void 0;
    (function (Variant) {
        Variant[Variant["MONOCHROME"] = 0] = "MONOCHROME";
        Variant[Variant["NEUTRAL"] = 1] = "NEUTRAL";
        Variant[Variant["TONAL_SPOT"] = 2] = "TONAL_SPOT";
        Variant[Variant["VIBRANT"] = 3] = "VIBRANT";
        Variant[Variant["EXPRESSIVE"] = 4] = "EXPRESSIVE";
        Variant[Variant["FIDELITY"] = 5] = "FIDELITY";
        Variant[Variant["CONTENT"] = 6] = "CONTENT";
        Variant[Variant["RAINBOW"] = 7] = "RAINBOW";
        Variant[Variant["FRUIT_SALAD"] = 8] = "FRUIT_SALAD";
    })(exports.Variant || (exports.Variant = {}));

    /**
     * @license
     * Copyright 2025 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Returns true if the scheme is Fidelity or Content.
     */
    function isFidelity(scheme) {
        return scheme.variant === exports.Variant.FIDELITY ||
            scheme.variant === exports.Variant.CONTENT;
    }
    /**
     * Returns true if the scheme is Monochrome.
     */
    function isMonochrome(scheme) {
        return scheme.variant === exports.Variant.MONOCHROME;
    }
    /**
     * Returns the desired chroma for a given tone at a specific hue.
     *
     * @param hue The given hue.
     * @param chroma The target chroma.
     * @param tone The tone to start with.
     * @param byDecreasingTone Whether to search for lower tones.
     */
    function findDesiredChromaByTone(hue, chroma, tone, byDecreasingTone) {
        var answer = tone;
        var closestToChroma = Hct.from(hue, chroma, tone);
        if (closestToChroma.chroma < chroma) {
            var chromaPeak = closestToChroma.chroma;
            while (closestToChroma.chroma < chroma) {
                answer += byDecreasingTone ? -1 : 1.0;
                var potentialSolution = Hct.from(hue, chroma, answer);
                if (chromaPeak > potentialSolution.chroma) {
                    break;
                }
                if (Math.abs(potentialSolution.chroma - chroma) < 0.4) {
                    break;
                }
                var potentialDelta = Math.abs(potentialSolution.chroma - chroma);
                var currentDelta = Math.abs(closestToChroma.chroma - chroma);
                if (potentialDelta < currentDelta) {
                    closestToChroma = potentialSolution;
                }
                chromaPeak = Math.max(chromaPeak, potentialSolution.chroma);
            }
        }
        return answer;
    }
    /**
     * A delegate for the dynamic color spec of a DynamicScheme in the 2021 spec.
     */
    var ColorSpecDelegateImpl2021 = /** @class */ (function () {
        function ColorSpecDelegateImpl2021() {
        }
        ////////////////////////////////////////////////////////////////
        // Main Palettes                                              //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.primaryPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'primary_palette_key_color',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return s.primaryPalette.keyColor.tone; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.secondaryPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'secondary_palette_key_color',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return s.secondaryPalette.keyColor.tone; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.tertiaryPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'tertiary_palette_key_color',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return s.tertiaryPalette.keyColor.tone; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.neutralPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'neutral_palette_key_color',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.neutralPalette.keyColor.tone; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.neutralVariantPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'neutral_variant_palette_key_color',
                palette: function (s) { return s.neutralVariantPalette; },
                tone: function (s) { return s.neutralVariantPalette.keyColor.tone; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.errorPaletteKeyColor = function () {
            return DynamicColor.fromPalette({
                name: 'error_palette_key_color',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) { return s.errorPalette.keyColor.tone; },
            });
        };
        ////////////////////////////////////////////////////////////////
        // Surfaces [S]                                               //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.background = function () {
            return DynamicColor.fromPalette({
                name: 'background',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 6 : 98; },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.onBackground = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_background',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 90 : 10; },
                background: function (s) { return _this.background(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 3, 4.5, 7); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.surface = function () {
            return DynamicColor.fromPalette({
                name: 'surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 6 : 98; },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceDim = function () {
            return DynamicColor.fromPalette({
                name: 'surface_dim',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    return s.isDark ? 6 : new ContrastCurve(87, 87, 80, 75).get(s.contrastLevel);
                },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceBright = function () {
            return DynamicColor.fromPalette({
                name: 'surface_bright',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ?
                    new ContrastCurve(24, 24, 29, 34).get(s.contrastLevel) :
                    98; },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceContainerLowest = function () {
            return DynamicColor.fromPalette({
                name: 'surface_container_lowest',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    return s.isDark ? new ContrastCurve(4, 4, 2, 0).get(s.contrastLevel) : 100;
                },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceContainerLow = function () {
            return DynamicColor.fromPalette({
                name: 'surface_container_low',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ?
                    new ContrastCurve(10, 10, 11, 12).get(s.contrastLevel) :
                    new ContrastCurve(96, 96, 96, 95).get(s.contrastLevel); },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceContainer = function () {
            return DynamicColor.fromPalette({
                name: 'surface_container',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ?
                    new ContrastCurve(12, 12, 16, 20).get(s.contrastLevel) :
                    new ContrastCurve(94, 94, 92, 90).get(s.contrastLevel); },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceContainerHigh = function () {
            return DynamicColor.fromPalette({
                name: 'surface_container_high',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ?
                    new ContrastCurve(17, 17, 21, 25).get(s.contrastLevel) :
                    new ContrastCurve(92, 92, 88, 85).get(s.contrastLevel); },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceContainerHighest = function () {
            return DynamicColor.fromPalette({
                name: 'surface_container_highest',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ?
                    new ContrastCurve(22, 22, 26, 30).get(s.contrastLevel) :
                    new ContrastCurve(90, 90, 84, 80).get(s.contrastLevel); },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.onSurface = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 90 : 10; },
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceVariant = function () {
            return DynamicColor.fromPalette({
                name: 'surface_variant',
                palette: function (s) { return s.neutralVariantPalette; },
                tone: function (s) { return s.isDark ? 30 : 90; },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.onSurfaceVariant = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_surface_variant',
                palette: function (s) { return s.neutralVariantPalette; },
                tone: function (s) { return s.isDark ? 80 : 30; },
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.inverseSurface = function () {
            return DynamicColor.fromPalette({
                name: 'inverse_surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 90 : 20; },
                isBackground: true,
            });
        };
        ColorSpecDelegateImpl2021.prototype.inverseOnSurface = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'inverse_on_surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 20 : 95; },
                background: function (s) { return _this.inverseSurface(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.outline = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'outline',
                palette: function (s) { return s.neutralVariantPalette; },
                tone: function (s) { return s.isDark ? 60 : 50; },
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1.5, 3, 4.5, 7); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.outlineVariant = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'outline_variant',
                palette: function (s) { return s.neutralVariantPalette; },
                tone: function (s) { return s.isDark ? 30 : 80; },
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.shadow = function () {
            return DynamicColor.fromPalette({
                name: 'shadow',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return 0; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.scrim = function () {
            return DynamicColor.fromPalette({
                name: 'scrim',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return 0; },
            });
        };
        ColorSpecDelegateImpl2021.prototype.surfaceTint = function () {
            return DynamicColor.fromPalette({
                name: 'surface_tint',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return s.isDark ? 80 : 40; },
                isBackground: true,
            });
        };
        ////////////////////////////////////////////////////////////////
        // Primary [P].                                               //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.primary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'primary',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 100 : 0;
                    }
                    return s.isDark ? 80 : 40;
                },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 7); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryContainer(), _this.primary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.primaryDim = function () {
            return undefined;
        };
        ColorSpecDelegateImpl2021.prototype.onPrimary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_primary',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 10 : 90;
                    }
                    return s.isDark ? 20 : 100;
                },
                background: function (s) { return _this.primary(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.primaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'primary_container',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (isFidelity(s)) {
                        return s.sourceColorHct.tone;
                    }
                    if (isMonochrome(s)) {
                        return s.isDark ? 85 : 25;
                    }
                    return s.isDark ? 30 : 90;
                },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryContainer(), _this.primary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onPrimaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_primary_container',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (isFidelity(s)) {
                        return DynamicColor.foregroundTone(_this.primaryContainer().tone(s), 4.5);
                    }
                    if (isMonochrome(s)) {
                        return s.isDark ? 0 : 100;
                    }
                    return s.isDark ? 90 : 30;
                },
                background: function (s) { return _this.primaryContainer(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.inversePrimary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'inverse_primary',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return s.isDark ? 40 : 80; },
                background: function (s) { return _this.inverseSurface(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 7); },
            });
        };
        /////////////////////////////////////////////////////////////////
        // Secondary [Q].                                              //
        /////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.secondary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'secondary',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return s.isDark ? 80 : 40; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 7); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryContainer(), _this.secondary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.secondaryDim = function () {
            return undefined;
        };
        ColorSpecDelegateImpl2021.prototype.onSecondary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_secondary',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 10 : 100;
                    }
                    else {
                        return s.isDark ? 20 : 100;
                    }
                },
                background: function (s) { return _this.secondary(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.secondaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'secondary_container',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    var initialTone = s.isDark ? 30 : 90;
                    if (isMonochrome(s)) {
                        return s.isDark ? 30 : 85;
                    }
                    if (!isFidelity(s)) {
                        return initialTone;
                    }
                    return findDesiredChromaByTone(s.secondaryPalette.hue, s.secondaryPalette.chroma, initialTone, s.isDark ? false : true);
                },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryContainer(), _this.secondary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onSecondaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_secondary_container',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 90 : 10;
                    }
                    if (!isFidelity(s)) {
                        return s.isDark ? 90 : 30;
                    }
                    return DynamicColor.foregroundTone(_this.secondaryContainer().tone(s), 4.5);
                },
                background: function (s) { return _this.secondaryContainer(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        /////////////////////////////////////////////////////////////////
        // Tertiary [T].                                               //
        /////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.tertiary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'tertiary',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 90 : 25;
                    }
                    return s.isDark ? 80 : 40;
                },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 7); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryContainer(), _this.tertiary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.tertiaryDim = function () {
            return undefined;
        };
        ColorSpecDelegateImpl2021.prototype.onTertiary = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_tertiary',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 10 : 90;
                    }
                    return s.isDark ? 20 : 100;
                },
                background: function (s) { return _this.tertiary(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.tertiaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'tertiary_container',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 60 : 49;
                    }
                    if (!isFidelity(s)) {
                        return s.isDark ? 30 : 90;
                    }
                    var proposedHct = s.tertiaryPalette.getHct(s.sourceColorHct.tone);
                    return DislikeAnalyzer.fixIfDisliked(proposedHct).tone;
                },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryContainer(), _this.tertiary(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onTertiaryContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_tertiary_container',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 0 : 100;
                    }
                    if (!isFidelity(s)) {
                        return s.isDark ? 90 : 30;
                    }
                    return DynamicColor.foregroundTone(_this.tertiaryContainer().tone(s), 4.5);
                },
                background: function (s) { return _this.tertiaryContainer(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        //////////////////////////////////////////////////////////////////
        // Error [E].                                                   //
        //////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.error = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'error',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) { return s.isDark ? 80 : 40; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 7); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.errorContainer(), _this.error(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.errorDim = function () {
            return undefined;
        };
        ColorSpecDelegateImpl2021.prototype.onError = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_error',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) { return s.isDark ? 20 : 100; },
                background: function (s) { return _this.error(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.errorContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'error_container',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) { return s.isDark ? 30 : 90; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.errorContainer(), _this.error(), 10, 'nearer', false); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onErrorContainer = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_error_container',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) {
                    if (isMonochrome(s)) {
                        return s.isDark ? 90 : 10;
                    }
                    return s.isDark ? 90 : 30;
                },
                background: function (s) { return _this.errorContainer(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        //////////////////////////////////////////////////////////////////
        // Primary Fixed [PF]                                           //
        //////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.primaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'primary_fixed',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 40.0 : 90.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryFixed(), _this.primaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.primaryFixedDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'primary_fixed_dim',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 30.0 : 80.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryFixed(), _this.primaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onPrimaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_primary_fixed',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 100.0 : 10.0; },
                background: function (s) { return _this.primaryFixedDim(); },
                secondBackground: function (s) { return _this.primaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onPrimaryFixedVariant = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_primary_fixed_variant',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 90.0 : 30.0; },
                background: function (s) { return _this.primaryFixedDim(); },
                secondBackground: function (s) { return _this.primaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        ///////////////////////////////////////////////////////////////////
        // Secondary Fixed [QF]                                          //
        ///////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.secondaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'secondary_fixed',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 80.0 : 90.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryFixed(), _this.secondaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.secondaryFixedDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'secondary_fixed_dim',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 70.0 : 80.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryFixed(), _this.secondaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onSecondaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_secondary_fixed',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return 10.0; },
                background: function (s) { return _this.secondaryFixedDim(); },
                secondBackground: function (s) { return _this.secondaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onSecondaryFixedVariant = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_secondary_fixed_variant',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 25.0 : 30.0; },
                background: function (s) { return _this.secondaryFixedDim(); },
                secondBackground: function (s) { return _this.secondaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        /////////////////////////////////////////////////////////////////
        // Tertiary Fixed [TF]                                         //
        /////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.tertiaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'tertiary_fixed',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 40.0 : 90.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryFixed(), _this.tertiaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.tertiaryFixedDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'tertiary_fixed_dim',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 30.0 : 80.0; },
                isBackground: true,
                background: function (s) { return _this.highestSurface(s); },
                contrastCurve: function (s) { return new ContrastCurve(1, 1, 3, 4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryFixed(), _this.tertiaryFixedDim(), 10, 'lighter', true); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onTertiaryFixed = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_tertiary_fixed',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 100.0 : 10.0; },
                background: function (s) { return _this.tertiaryFixedDim(); },
                secondBackground: function (s) { return _this.tertiaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(4.5, 7, 11, 21); },
            });
        };
        ColorSpecDelegateImpl2021.prototype.onTertiaryFixedVariant = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'on_tertiary_fixed_variant',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return isMonochrome(s) ? 90.0 : 30.0; },
                background: function (s) { return _this.tertiaryFixedDim(); },
                secondBackground: function (s) { return _this.tertiaryFixed(); },
                contrastCurve: function (s) { return new ContrastCurve(3, 4.5, 7, 11); },
            });
        };
        ////////////////////////////////////////////////////////////////
        // Other                                                      //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2021.prototype.highestSurface = function (s) {
            return s.isDark ? this.surfaceBright() : this.surfaceDim();
        };
        return ColorSpecDelegateImpl2021;
    }());

    /**
     * @license
     * Copyright 2025 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Returns the maximum tone for a given chroma in the palette.
     *
     * @param palette The tonal palette to use.
     * @param lowerBound The lower bound of the tone.
     * @param upperBound The upper bound of the tone.
     */
    function tMaxC(palette, lowerBound, upperBound, chromaMultiplier) {
        if (lowerBound === void 0) { lowerBound = 0; }
        if (upperBound === void 0) { upperBound = 100; }
        if (chromaMultiplier === void 0) { chromaMultiplier = 1; }
        var answer = findBestToneForChroma(palette.hue, palette.chroma * chromaMultiplier, 100, true);
        return clampDouble(lowerBound, upperBound, answer);
    }
    /**
     * Returns the minimum tone for a given chroma in the palette.
     *
     * @param palette The tonal palette to use.
     * @param lowerBound The lower bound of the tone.
     * @param upperBound The upper bound of the tone.
     */
    function tMinC(palette, lowerBound, upperBound) {
        if (lowerBound === void 0) { lowerBound = 0; }
        if (upperBound === void 0) { upperBound = 100; }
        var answer = findBestToneForChroma(palette.hue, palette.chroma, 0, false);
        return clampDouble(lowerBound, upperBound, answer);
    }
    /**
     * Searches for the best tone with a given chroma from a given tone at a
     * specific hue.
     *
     * @param hue The given hue.
     * @param chroma The target chroma.
     * @param tone The tone to start with.
     * @param byDecreasingTone Whether to search for lower tones.
     */
    function findBestToneForChroma(hue, chroma, tone, byDecreasingTone) {
        var answer = tone;
        var bestCandidate = Hct.from(hue, chroma, answer);
        while (bestCandidate.chroma < chroma) {
            if (tone < 0 || tone > 100) {
                break;
            }
            tone += byDecreasingTone ? -1 : 1.0;
            var newCandidate = Hct.from(hue, chroma, tone);
            if (bestCandidate.chroma < newCandidate.chroma) {
                bestCandidate = newCandidate;
                answer = tone;
            }
        }
        return answer;
    }
    /**
     * Returns the contrast curve for a given default contrast.
     *
     * @param defaultContrast The default contrast to use.
     */
    function getCurve(defaultContrast) {
        if (defaultContrast === 1.5) {
            return new ContrastCurve(1.5, 1.5, 3, 5.5);
        }
        else if (defaultContrast === 3) {
            return new ContrastCurve(3, 3, 4.5, 7);
        }
        else if (defaultContrast === 4.5) {
            return new ContrastCurve(4.5, 4.5, 7, 11);
        }
        else if (defaultContrast === 6) {
            return new ContrastCurve(6, 6, 7, 11);
        }
        else if (defaultContrast === 7) {
            return new ContrastCurve(7, 7, 11, 21);
        }
        else if (defaultContrast === 9) {
            return new ContrastCurve(9, 9, 11, 21);
        }
        else if (defaultContrast === 11) {
            return new ContrastCurve(11, 11, 21, 21);
        }
        else if (defaultContrast === 21) {
            return new ContrastCurve(21, 21, 21, 21);
        }
        else {
            // Shouldn't happen.
            return new ContrastCurve(defaultContrast, defaultContrast, 7, 21);
        }
    }
    /**
     * A delegate for the dynamic color spec of a DynamicScheme in the 2025 spec.
     */
    var ColorSpecDelegateImpl2025 = /** @class */ (function (_super) {
        __extends(ColorSpecDelegateImpl2025, _super);
        function ColorSpecDelegateImpl2025() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        ////////////////////////////////////////////////////////////////
        // Surfaces [S]                                               //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.surface = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    _super.prototype.surface.call(_this).tone(s);
                    if (s.platform === 'phone') {
                        if (s.isDark) {
                            return 4;
                        }
                        else {
                            if (Hct.isYellow(s.neutralPalette.hue)) {
                                return 99;
                            }
                            else if (s.variant === exports.Variant.VIBRANT) {
                                return 97;
                            }
                            else {
                                return 98;
                            }
                        }
                    }
                    else {
                        return 0;
                    }
                },
                isBackground: true,
            });
            return extendSpecVersion(_super.prototype.surface.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceDim = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_dim',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.isDark) {
                        return 4;
                    }
                    else {
                        if (Hct.isYellow(s.neutralPalette.hue)) {
                            return 90;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 85;
                        }
                        else {
                            return 87;
                        }
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (!s.isDark) {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.5;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? 2.7 : 1.75;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 1.36;
                        }
                    }
                    return 1;
                },
            });
            return extendSpecVersion(_super.prototype.surfaceDim.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceBright = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_bright',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.isDark) {
                        return 18;
                    }
                    else {
                        if (Hct.isYellow(s.neutralPalette.hue)) {
                            return 99;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 97;
                        }
                        else {
                            return 98;
                        }
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (s.isDark) {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.5;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? 2.7 : 1.75;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 1.36;
                        }
                    }
                    return 1;
                },
            });
            return extendSpecVersion(_super.prototype.surfaceBright.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceContainerLowest = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_container_lowest',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 0 : 100; },
                isBackground: true,
            });
            return extendSpecVersion(_super.prototype.surfaceContainerLowest.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceContainerLow = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_container_low',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.platform === 'phone') {
                        if (s.isDark) {
                            return 6;
                        }
                        else {
                            if (Hct.isYellow(s.neutralPalette.hue)) {
                                return 98;
                            }
                            else if (s.variant === exports.Variant.VIBRANT) {
                                return 95;
                            }
                            else {
                                return 96;
                            }
                        }
                    }
                    else {
                        return 15;
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 1.3;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.25;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? 1.3 : 1.15;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 1.08;
                        }
                    }
                    return 1;
                },
            });
            return extendSpecVersion(_super.prototype.surfaceContainerLow.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceContainer = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_container',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.platform === 'phone') {
                        if (s.isDark) {
                            return 9;
                        }
                        else {
                            if (Hct.isYellow(s.neutralPalette.hue)) {
                                return 96;
                            }
                            else if (s.variant === exports.Variant.VIBRANT) {
                                return 92;
                            }
                            else {
                                return 94;
                            }
                        }
                    }
                    else {
                        return 20;
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 1.6;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.4;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? 1.6 : 1.3;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 1.15;
                        }
                    }
                    return 1;
                },
            });
            return extendSpecVersion(_super.prototype.surfaceContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceContainerHigh = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_container_high',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.platform === 'phone') {
                        if (s.isDark) {
                            return 12;
                        }
                        else {
                            if (Hct.isYellow(s.neutralPalette.hue)) {
                                return 94;
                            }
                            else if (s.variant === exports.Variant.VIBRANT) {
                                return 90;
                            }
                            else {
                                return 92;
                            }
                        }
                    }
                    else {
                        return 25;
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 1.9;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.5;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? 1.95 : 1.45;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 1.22;
                        }
                    }
                    return 1;
                },
            });
            return extendSpecVersion(_super.prototype.surfaceContainerHigh.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceContainerHighest = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'surface_container_highest',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.isDark) {
                        return 15;
                    }
                    else {
                        if (Hct.isYellow(s.neutralPalette.hue)) {
                            return 92;
                        }
                        else if (s.variant === exports.Variant.VIBRANT) {
                            return 88;
                        }
                        else {
                            return 90;
                        }
                    }
                },
                isBackground: true,
                chromaMultiplier: function (s) {
                    if (s.variant === exports.Variant.NEUTRAL) {
                        return 2.2;
                    }
                    else if (s.variant === exports.Variant.TONAL_SPOT) {
                        return 1.7;
                    }
                    else if (s.variant === exports.Variant.EXPRESSIVE) {
                        return Hct.isYellow(s.neutralPalette.hue) ? 2.3 : 1.6;
                    }
                    else if (s.variant === exports.Variant.VIBRANT) {
                        return 1.29;
                    }
                    else { // default
                        return 1;
                    }
                },
            });
            return extendSpecVersion(_super.prototype.surfaceContainerHighest.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onSurface = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) {
                    if (s.variant === exports.Variant.VIBRANT) {
                        return tMaxC(s.neutralPalette, 0, 100, 1.1);
                    }
                    else {
                        // For all other variants, the initial tone should be the default
                        // tone, which is the same as the background color.
                        return DynamicColor.getInitialToneFromBackground(function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                            _this.surfaceContainerHigh(); })(s);
                    }
                },
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.2;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? (s.isDark ? 3.0 : 2.3) :
                                1.6;
                        }
                    }
                    return 1;
                },
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.isDark && s.platform === 'phone' ? getCurve(11) : getCurve(9);
                },
            });
            return extendSpecVersion(_super.prototype.onSurface.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onSurfaceVariant = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_surface_variant',
                palette: function (s) { return s.neutralPalette; },
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.2;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? (s.isDark ? 3.0 : 2.3) :
                                1.6;
                        }
                    }
                    return 1;
                },
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) { return s.platform === 'phone' ?
                    (s.isDark ? getCurve(6) : getCurve(4.5)) :
                    getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onSurfaceVariant.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.outline = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'outline',
                palette: function (s) { return s.neutralPalette; },
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.2;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? (s.isDark ? 3.0 : 2.3) :
                                1.6;
                        }
                    }
                    return 1;
                },
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(3) : getCurve(4.5);
                },
            });
            return extendSpecVersion(_super.prototype.outline.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.outlineVariant = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'outline_variant',
                palette: function (s) { return s.neutralPalette; },
                chromaMultiplier: function (s) {
                    if (s.platform === 'phone') {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return 2.2;
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return 1.7;
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return Hct.isYellow(s.neutralPalette.hue) ? (s.isDark ? 3.0 : 2.3) :
                                1.6;
                        }
                    }
                    return 1;
                },
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(1.5) : getCurve(3);
                },
            });
            return extendSpecVersion(_super.prototype.outlineVariant.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.inverseSurface = function () {
            var color2025 = DynamicColor.fromPalette({
                name: 'inverse_surface',
                palette: function (s) { return s.neutralPalette; },
                tone: function (s) { return s.isDark ? 98 : 4; },
                isBackground: true,
            });
            return extendSpecVersion(_super.prototype.inverseSurface.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.inverseOnSurface = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'inverse_on_surface',
                palette: function (s) { return s.neutralPalette; },
                background: function (s) { return _this.inverseSurface(); },
                contrastCurve: function (s) { return getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.inverseOnSurface.call(this), '2025', color2025);
        };
        ////////////////////////////////////////////////////////////////
        // Primaries [P]                                              //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.primary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'primary',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (s.variant === exports.Variant.NEUTRAL) {
                        if (s.platform === 'phone') {
                            return s.isDark ? 80 : 40;
                        }
                        else {
                            return 90;
                        }
                    }
                    else if (s.variant === exports.Variant.TONAL_SPOT) {
                        if (s.platform === 'phone') {
                            if (s.isDark) {
                                return 80;
                            }
                            else {
                                return tMaxC(s.primaryPalette);
                            }
                        }
                        else {
                            return tMaxC(s.primaryPalette, 0, 90);
                        }
                    }
                    else if (s.variant === exports.Variant.EXPRESSIVE) {
                        if (s.platform === 'phone') {
                            return tMaxC(s.primaryPalette, 0, Hct.isYellow(s.primaryPalette.hue) ? 25 :
                                Hct.isCyan(s.primaryPalette.hue) ? 88 :
                                    98);
                        }
                        else { // WATCH
                            return tMaxC(s.primaryPalette);
                        }
                    }
                    else { // VIBRANT
                        if (s.platform === 'phone') {
                            return tMaxC(s.primaryPalette, 0, Hct.isCyan(s.primaryPalette.hue) ? 88 : 98);
                        }
                        else { // WATCH
                            return tMaxC(s.primaryPalette);
                        }
                    }
                },
                isBackground: true,
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(4.5) : getCurve(7);
                },
                toneDeltaPair: function (s) { return s.platform === 'phone' ?
                    new ToneDeltaPair(_this.primaryContainer(), _this.primary(), 5, 'relative_lighter', true, 'farther') :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.primary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.primaryDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'primary_dim',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (s.variant === exports.Variant.NEUTRAL) {
                        return 85;
                    }
                    else if (s.variant === exports.Variant.TONAL_SPOT) {
                        return tMaxC(s.primaryPalette, 0, 90);
                    }
                    else {
                        return tMaxC(s.primaryPalette);
                    }
                },
                isBackground: true,
                background: function (s) { return _this.surfaceContainerHigh(); },
                contrastCurve: function (s) { return getCurve(4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryDim(), _this.primary(), 5, 'darker', true, 'farther'); },
            });
        };
        ColorSpecDelegateImpl2025.prototype.onPrimary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_primary',
                palette: function (s) { return s.primaryPalette; },
                background: function (s) {
                    return s.platform === 'phone' ? _this.primary() : _this.primaryDim();
                },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onPrimary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.primaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'primary_container',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return 30;
                    }
                    else if (s.variant === exports.Variant.NEUTRAL) {
                        return s.isDark ? 30 : 90;
                    }
                    else if (s.variant === exports.Variant.TONAL_SPOT) {
                        return s.isDark ? tMinC(s.primaryPalette, 35, 93) :
                            tMaxC(s.primaryPalette, 0, 90);
                    }
                    else if (s.variant === exports.Variant.EXPRESSIVE) {
                        return s.isDark ? tMaxC(s.primaryPalette, 30, 93) :
                            tMaxC(s.primaryPalette, 78, Hct.isCyan(s.primaryPalette.hue) ? 88 : 90);
                    }
                    else { // VIBRANT
                        return s.isDark ? tMinC(s.primaryPalette, 66, 93) :
                            tMaxC(s.primaryPalette, 66, Hct.isCyan(s.primaryPalette.hue) ? 88 : 93);
                    }
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                toneDeltaPair: function (s) { return s.platform === 'phone' ?
                    undefined :
                    new ToneDeltaPair(_this.primaryContainer(), _this.primaryDim(), 10, 'darker', true, 'farther'); },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.primaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onPrimaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_primary_container',
                palette: function (s) { return s.primaryPalette; },
                background: function (s) { return _this.primaryContainer(); },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onPrimaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.primaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'primary_fixed',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) {
                    var tempS = Object.assign({}, s, { isDark: false, contrastLevel: 0 });
                    return _this.primaryContainer().getTone(tempS);
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.primaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.primaryFixedDim = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'primary_fixed_dim',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return _this.primaryFixed().getTone(s); },
                isBackground: true,
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.primaryFixedDim(), _this.primaryFixed(), 5, 'darker', true, 'exact'); },
            });
            return extendSpecVersion(_super.prototype.primaryFixedDim.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onPrimaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_primary_fixed',
                palette: function (s) { return s.primaryPalette; },
                background: function (s) { return _this.primaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onPrimaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onPrimaryFixedVariant = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_primary_fixed_variant',
                palette: function (s) { return s.primaryPalette; },
                background: function (s) { return _this.primaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(4.5); },
            });
            return extendSpecVersion(_super.prototype.onPrimaryFixedVariant.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.inversePrimary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'inverse_primary',
                palette: function (s) { return s.primaryPalette; },
                tone: function (s) { return tMaxC(s.primaryPalette); },
                background: function (s) { return _this.inverseSurface(); },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.inversePrimary.call(this), '2025', color2025);
        };
        ////////////////////////////////////////////////////////////////
        // Secondaries [Q]                                            //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.secondary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'secondary',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return s.variant === exports.Variant.NEUTRAL ?
                            90 :
                            tMaxC(s.secondaryPalette, 0, 90);
                    }
                    else if (s.variant === exports.Variant.NEUTRAL) {
                        return s.isDark ? tMinC(s.secondaryPalette, 0, 98) :
                            tMaxC(s.secondaryPalette);
                    }
                    else if (s.variant === exports.Variant.VIBRANT) {
                        return tMaxC(s.secondaryPalette, 0, s.isDark ? 90 : 98);
                    }
                    else { // EXPRESSIVE and TONAL_SPOT
                        return s.isDark ? 80 : tMaxC(s.secondaryPalette);
                    }
                },
                isBackground: true,
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(4.5) : getCurve(7);
                },
                toneDeltaPair: function (s) { return s.platform === 'phone' ?
                    new ToneDeltaPair(_this.secondaryContainer(), _this.secondary(), 5, 'relative_lighter', true, 'farther') :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.secondary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.secondaryDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'secondary_dim',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    if (s.variant === exports.Variant.NEUTRAL) {
                        return 85;
                    }
                    else {
                        return tMaxC(s.secondaryPalette, 0, 90);
                    }
                },
                isBackground: true,
                background: function (s) { return _this.surfaceContainerHigh(); },
                contrastCurve: function (s) { return getCurve(4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryDim(), _this.secondary(), 5, 'darker', true, 'farther'); },
            });
        };
        ColorSpecDelegateImpl2025.prototype.onSecondary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_secondary',
                palette: function (s) { return s.secondaryPalette; },
                background: function (s) {
                    return s.platform === 'phone' ? _this.secondary() : _this.secondaryDim();
                },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onSecondary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.secondaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'secondary_container',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return 30;
                    }
                    else if (s.variant === exports.Variant.VIBRANT) {
                        return s.isDark ? tMinC(s.secondaryPalette, 30, 40) :
                            tMaxC(s.secondaryPalette, 84, 90);
                    }
                    else if (s.variant === exports.Variant.EXPRESSIVE) {
                        return s.isDark ? 15 : tMaxC(s.secondaryPalette, 90, 95);
                    }
                    else {
                        return s.isDark ? 25 : 90;
                    }
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                toneDeltaPair: function (s) { return s.platform === 'watch' ?
                    new ToneDeltaPair(_this.secondaryContainer(), _this.secondaryDim(), 10, 'darker', true, 'farther') :
                    undefined; },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.secondaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onSecondaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_secondary_container',
                palette: function (s) { return s.secondaryPalette; },
                background: function (s) { return _this.secondaryContainer(); },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onSecondaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.secondaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'secondary_fixed',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) {
                    var tempS = Object.assign({}, s, { isDark: false, contrastLevel: 0 });
                    return _this.secondaryContainer().getTone(tempS);
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.secondaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.secondaryFixedDim = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'secondary_fixed_dim',
                palette: function (s) { return s.secondaryPalette; },
                tone: function (s) { return _this.secondaryFixed().getTone(s); },
                isBackground: true,
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.secondaryFixedDim(), _this.secondaryFixed(), 5, 'darker', true, 'exact'); },
            });
            return extendSpecVersion(_super.prototype.secondaryFixedDim.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onSecondaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_secondary_fixed',
                palette: function (s) { return s.secondaryPalette; },
                background: function (s) { return _this.secondaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onSecondaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onSecondaryFixedVariant = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_secondary_fixed_variant',
                palette: function (s) { return s.secondaryPalette; },
                background: function (s) { return _this.secondaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(4.5); },
            });
            return extendSpecVersion(_super.prototype.onSecondaryFixedVariant.call(this), '2025', color2025);
        };
        ////////////////////////////////////////////////////////////////
        // Tertiaries [T]                                             //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.tertiary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'tertiary',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return s.variant === exports.Variant.TONAL_SPOT ?
                            tMaxC(s.tertiaryPalette, 0, 90) :
                            tMaxC(s.tertiaryPalette);
                    }
                    else if (s.variant === exports.Variant.EXPRESSIVE || s.variant === exports.Variant.VIBRANT) {
                        return tMaxC(s.tertiaryPalette, 0, Hct.isCyan(s.tertiaryPalette.hue) ? 88 : (s.isDark ? 98 : 100));
                    }
                    else { // NEUTRAL and TONAL_SPOT
                        return s.isDark ? tMaxC(s.tertiaryPalette, 0, 98) :
                            tMaxC(s.tertiaryPalette);
                    }
                },
                isBackground: true,
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(4.5) : getCurve(7);
                },
                toneDeltaPair: function (s) { return s.platform === 'phone' ?
                    new ToneDeltaPair(_this.tertiaryContainer(), _this.tertiary(), 5, 'relative_lighter', true, 'farther') :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.tertiary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.tertiaryDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'tertiary_dim',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (s.variant === exports.Variant.TONAL_SPOT) {
                        return tMaxC(s.tertiaryPalette, 0, 90);
                    }
                    else {
                        return tMaxC(s.tertiaryPalette);
                    }
                },
                isBackground: true,
                background: function (s) { return _this.surfaceContainerHigh(); },
                contrastCurve: function (s) { return getCurve(4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryDim(), _this.tertiary(), 5, 'darker', true, 'farther'); },
            });
        };
        ColorSpecDelegateImpl2025.prototype.onTertiary = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_tertiary',
                palette: function (s) { return s.tertiaryPalette; },
                background: function (s) {
                    return s.platform === 'phone' ? _this.tertiary() : _this.tertiaryDim();
                },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onTertiary.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.tertiaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'tertiary_container',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return s.variant === exports.Variant.TONAL_SPOT ?
                            tMaxC(s.tertiaryPalette, 0, 90) :
                            tMaxC(s.tertiaryPalette);
                    }
                    else {
                        if (s.variant === exports.Variant.NEUTRAL) {
                            return s.isDark ? tMaxC(s.tertiaryPalette, 0, 93) :
                                tMaxC(s.tertiaryPalette, 0, 96);
                        }
                        else if (s.variant === exports.Variant.TONAL_SPOT) {
                            return tMaxC(s.tertiaryPalette, 0, s.isDark ? 93 : 100);
                        }
                        else if (s.variant === exports.Variant.EXPRESSIVE) {
                            return tMaxC(s.tertiaryPalette, 75, Hct.isCyan(s.tertiaryPalette.hue) ? 88 : (s.isDark ? 93 : 100));
                        }
                        else { // VIBRANT
                            return s.isDark ? tMaxC(s.tertiaryPalette, 0, 93) :
                                tMaxC(s.tertiaryPalette, 72, 100);
                        }
                    }
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                toneDeltaPair: function (s) { return s.platform === 'watch' ?
                    new ToneDeltaPair(_this.tertiaryContainer(), _this.tertiaryDim(), 10, 'darker', true, 'farther') :
                    undefined; },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.tertiaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onTertiaryContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_tertiary_container',
                palette: function (s) { return s.tertiaryPalette; },
                background: function (s) { return _this.tertiaryContainer(); },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onTertiaryContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.tertiaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'tertiary_fixed',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) {
                    var tempS = Object.assign({}, s, { isDark: false, contrastLevel: 0 });
                    return _this.tertiaryContainer().getTone(tempS);
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.tertiaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.tertiaryFixedDim = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'tertiary_fixed_dim',
                palette: function (s) { return s.tertiaryPalette; },
                tone: function (s) { return _this.tertiaryFixed().getTone(s); },
                isBackground: true,
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.tertiaryFixedDim(), _this.tertiaryFixed(), 5, 'darker', true, 'exact'); },
            });
            return extendSpecVersion(_super.prototype.tertiaryFixedDim.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onTertiaryFixed = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_tertiary_fixed',
                palette: function (s) { return s.tertiaryPalette; },
                background: function (s) { return _this.tertiaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onTertiaryFixed.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onTertiaryFixedVariant = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_tertiary_fixed_variant',
                palette: function (s) { return s.tertiaryPalette; },
                background: function (s) { return _this.tertiaryFixedDim(); },
                contrastCurve: function (s) { return getCurve(4.5); },
            });
            return extendSpecVersion(_super.prototype.onTertiaryFixedVariant.call(this), '2025', color2025);
        };
        ////////////////////////////////////////////////////////////////
        // Errors [E]                                                 //
        ////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.error = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'error',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) {
                    if (s.platform === 'phone') {
                        return s.isDark ? tMinC(s.errorPalette, 0, 98) :
                            tMaxC(s.errorPalette);
                    }
                    else {
                        return tMinC(s.errorPalette);
                    }
                },
                isBackground: true,
                background: function (s) { return s.platform === 'phone' ? _this.highestSurface(s) :
                    _this.surfaceContainerHigh(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(4.5) : getCurve(7);
                },
                toneDeltaPair: function (s) { return s.platform === 'phone' ?
                    new ToneDeltaPair(_this.errorContainer(), _this.error(), 5, 'relative_lighter', true, 'farther') :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.error.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.errorDim = function () {
            var _this = this;
            return DynamicColor.fromPalette({
                name: 'error_dim',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) { return tMinC(s.errorPalette); },
                isBackground: true,
                background: function (s) { return _this.surfaceContainerHigh(); },
                contrastCurve: function (s) { return getCurve(4.5); },
                toneDeltaPair: function (s) { return new ToneDeltaPair(_this.errorDim(), _this.error(), 5, 'darker', true, 'farther'); },
            });
        };
        ColorSpecDelegateImpl2025.prototype.onError = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_error',
                palette: function (s) { return s.errorPalette; },
                background: function (s) {
                    return s.platform === 'phone' ? _this.error() : _this.errorDim();
                },
                contrastCurve: function (s) { return s.platform === 'phone' ? getCurve(6) : getCurve(7); },
            });
            return extendSpecVersion(_super.prototype.onError.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.errorContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'error_container',
                palette: function (s) { return s.errorPalette; },
                tone: function (s) {
                    if (s.platform === 'watch') {
                        return 30;
                    }
                    else {
                        return s.isDark ? tMinC(s.errorPalette, 30, 93) :
                            tMaxC(s.errorPalette, 0, 90);
                    }
                },
                isBackground: true,
                background: function (s) {
                    return s.platform === 'phone' ? _this.highestSurface(s) : undefined;
                },
                toneDeltaPair: function (s) { return s.platform === 'watch' ?
                    new ToneDeltaPair(_this.errorContainer(), _this.errorDim(), 10, 'darker', true, 'farther') :
                    undefined; },
                contrastCurve: function (s) { return s.platform === 'phone' && s.contrastLevel > 0 ?
                    getCurve(1.5) :
                    undefined; },
            });
            return extendSpecVersion(_super.prototype.errorContainer.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onErrorContainer = function () {
            var _this = this;
            var color2025 = DynamicColor.fromPalette({
                name: 'on_error_container',
                palette: function (s) { return s.errorPalette; },
                background: function (s) { return _this.errorContainer(); },
                contrastCurve: function (s) {
                    return s.platform === 'phone' ? getCurve(4.5) : getCurve(7);
                },
            });
            return extendSpecVersion(_super.prototype.onErrorContainer.call(this), '2025', color2025);
        };
        /////////////////////////////////////////////////////////////////
        // Remapped Colors                                             //
        /////////////////////////////////////////////////////////////////
        ColorSpecDelegateImpl2025.prototype.surfaceVariant = function () {
            var color2025 = Object.assign(this.surfaceContainerHighest().clone(), { name: 'surface_variant' });
            return extendSpecVersion(_super.prototype.surfaceVariant.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.surfaceTint = function () {
            var color2025 = Object.assign(this.primary().clone(), { name: 'surface_tint' });
            return extendSpecVersion(_super.prototype.surfaceTint.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.background = function () {
            var color2025 = Object.assign(this.surface().clone(), { name: 'background' });
            return extendSpecVersion(_super.prototype.background.call(this), '2025', color2025);
        };
        ColorSpecDelegateImpl2025.prototype.onBackground = function () {
            var _this = this;
            var color2025 = Object.assign(this.onSurface().clone(), {
                name: 'on_background',
                tone: function (s) {
                    return s.platform === 'watch' ? 100.0 : _this.onSurface().getTone(s);
                }
            });
            return extendSpecVersion(_super.prototype.onBackground.call(this), '2025', color2025);
        };
        return ColorSpecDelegateImpl2025;
    }(ColorSpecDelegateImpl2021));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * DynamicColors for the colors in the Material Design system.
     */
    // Material Color Utilities namespaces the various utilities it provides.
    // tslint:disable-next-line:class-as-namespace
    var MaterialDynamicColors = /** @class */ (function () {
        function MaterialDynamicColors() {
            ////////////////////////////////////////////////////////////////
            // All Colors                                                 //
            ////////////////////////////////////////////////////////////////
            this.allColors = [
                this.background(),
                this.onBackground(),
                this.surface(),
                this.surfaceDim(),
                this.surfaceBright(),
                this.surfaceContainerLowest(),
                this.surfaceContainerLow(),
                this.surfaceContainer(),
                this.surfaceContainerHigh(),
                this.surfaceContainerHighest(),
                this.onSurface(),
                this.onSurfaceVariant(),
                this.outline(),
                this.outlineVariant(),
                this.inverseSurface(),
                this.inverseOnSurface(),
                this.primary(),
                this.primaryDim(),
                this.onPrimary(),
                this.primaryContainer(),
                this.onPrimaryContainer(),
                this.primaryFixed(),
                this.primaryFixedDim(),
                this.onPrimaryFixed(),
                this.onPrimaryFixedVariant(),
                this.inversePrimary(),
                this.secondary(),
                this.secondaryDim(),
                this.onSecondary(),
                this.secondaryContainer(),
                this.onSecondaryContainer(),
                this.secondaryFixed(),
                this.secondaryFixedDim(),
                this.onSecondaryFixed(),
                this.onSecondaryFixedVariant(),
                this.tertiary(),
                this.tertiaryDim(),
                this.onTertiary(),
                this.tertiaryContainer(),
                this.onTertiaryContainer(),
                this.tertiaryFixed(),
                this.tertiaryFixedDim(),
                this.onTertiaryFixed(),
                this.onTertiaryFixedVariant(),
                this.error(),
                this.errorDim(),
                this.onError(),
                this.errorContainer(),
                this.onErrorContainer(),
            ].filter(function (c) { return c !== undefined; });
        }
        MaterialDynamicColors.prototype.highestSurface = function (s) {
            return MaterialDynamicColors.colorSpec.highestSurface(s);
        };
        ////////////////////////////////////////////////////////////////
        // Main Palettes                                              //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.primaryPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.primaryPaletteKeyColor();
        };
        MaterialDynamicColors.prototype.secondaryPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.secondaryPaletteKeyColor();
        };
        MaterialDynamicColors.prototype.tertiaryPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.tertiaryPaletteKeyColor();
        };
        MaterialDynamicColors.prototype.neutralPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.neutralPaletteKeyColor();
        };
        MaterialDynamicColors.prototype.neutralVariantPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.neutralVariantPaletteKeyColor();
        };
        MaterialDynamicColors.prototype.errorPaletteKeyColor = function () {
            return MaterialDynamicColors.colorSpec.errorPaletteKeyColor();
        };
        ////////////////////////////////////////////////////////////////
        // Surfaces [S]                                               //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.background = function () {
            return MaterialDynamicColors.colorSpec.background();
        };
        MaterialDynamicColors.prototype.onBackground = function () {
            return MaterialDynamicColors.colorSpec.onBackground();
        };
        MaterialDynamicColors.prototype.surface = function () {
            return MaterialDynamicColors.colorSpec.surface();
        };
        MaterialDynamicColors.prototype.surfaceDim = function () {
            return MaterialDynamicColors.colorSpec.surfaceDim();
        };
        MaterialDynamicColors.prototype.surfaceBright = function () {
            return MaterialDynamicColors.colorSpec.surfaceBright();
        };
        MaterialDynamicColors.prototype.surfaceContainerLowest = function () {
            return MaterialDynamicColors.colorSpec.surfaceContainerLowest();
        };
        MaterialDynamicColors.prototype.surfaceContainerLow = function () {
            return MaterialDynamicColors.colorSpec.surfaceContainerLow();
        };
        MaterialDynamicColors.prototype.surfaceContainer = function () {
            return MaterialDynamicColors.colorSpec.surfaceContainer();
        };
        MaterialDynamicColors.prototype.surfaceContainerHigh = function () {
            return MaterialDynamicColors.colorSpec.surfaceContainerHigh();
        };
        MaterialDynamicColors.prototype.surfaceContainerHighest = function () {
            return MaterialDynamicColors.colorSpec.surfaceContainerHighest();
        };
        MaterialDynamicColors.prototype.onSurface = function () {
            return MaterialDynamicColors.colorSpec.onSurface();
        };
        MaterialDynamicColors.prototype.surfaceVariant = function () {
            return MaterialDynamicColors.colorSpec.surfaceVariant();
        };
        MaterialDynamicColors.prototype.onSurfaceVariant = function () {
            return MaterialDynamicColors.colorSpec.onSurfaceVariant();
        };
        MaterialDynamicColors.prototype.outline = function () {
            return MaterialDynamicColors.colorSpec.outline();
        };
        MaterialDynamicColors.prototype.outlineVariant = function () {
            return MaterialDynamicColors.colorSpec.outlineVariant();
        };
        MaterialDynamicColors.prototype.inverseSurface = function () {
            return MaterialDynamicColors.colorSpec.inverseSurface();
        };
        MaterialDynamicColors.prototype.inverseOnSurface = function () {
            return MaterialDynamicColors.colorSpec.inverseOnSurface();
        };
        MaterialDynamicColors.prototype.shadow = function () {
            return MaterialDynamicColors.colorSpec.shadow();
        };
        MaterialDynamicColors.prototype.scrim = function () {
            return MaterialDynamicColors.colorSpec.scrim();
        };
        MaterialDynamicColors.prototype.surfaceTint = function () {
            return MaterialDynamicColors.colorSpec.surfaceTint();
        };
        ////////////////////////////////////////////////////////////////
        // Primaries [P]                                              //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.primary = function () {
            return MaterialDynamicColors.colorSpec.primary();
        };
        MaterialDynamicColors.prototype.primaryDim = function () {
            return MaterialDynamicColors.colorSpec.primaryDim();
        };
        MaterialDynamicColors.prototype.onPrimary = function () {
            return MaterialDynamicColors.colorSpec.onPrimary();
        };
        MaterialDynamicColors.prototype.primaryContainer = function () {
            return MaterialDynamicColors.colorSpec.primaryContainer();
        };
        MaterialDynamicColors.prototype.onPrimaryContainer = function () {
            return MaterialDynamicColors.colorSpec.onPrimaryContainer();
        };
        MaterialDynamicColors.prototype.inversePrimary = function () {
            return MaterialDynamicColors.colorSpec.inversePrimary();
        };
        /////////////////////////////////////////////////////////////////
        // Primary Fixed [PF]                                          //
        /////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.primaryFixed = function () {
            return MaterialDynamicColors.colorSpec.primaryFixed();
        };
        MaterialDynamicColors.prototype.primaryFixedDim = function () {
            return MaterialDynamicColors.colorSpec.primaryFixedDim();
        };
        MaterialDynamicColors.prototype.onPrimaryFixed = function () {
            return MaterialDynamicColors.colorSpec.onPrimaryFixed();
        };
        MaterialDynamicColors.prototype.onPrimaryFixedVariant = function () {
            return MaterialDynamicColors.colorSpec.onPrimaryFixedVariant();
        };
        ////////////////////////////////////////////////////////////////
        // Secondaries [Q]                                            //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.secondary = function () {
            return MaterialDynamicColors.colorSpec.secondary();
        };
        MaterialDynamicColors.prototype.secondaryDim = function () {
            return MaterialDynamicColors.colorSpec.secondaryDim();
        };
        MaterialDynamicColors.prototype.onSecondary = function () {
            return MaterialDynamicColors.colorSpec.onSecondary();
        };
        MaterialDynamicColors.prototype.secondaryContainer = function () {
            return MaterialDynamicColors.colorSpec.secondaryContainer();
        };
        MaterialDynamicColors.prototype.onSecondaryContainer = function () {
            return MaterialDynamicColors.colorSpec.onSecondaryContainer();
        };
        /////////////////////////////////////////////////////////////////
        // Secondary Fixed [QF]                                        //
        /////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.secondaryFixed = function () {
            return MaterialDynamicColors.colorSpec.secondaryFixed();
        };
        MaterialDynamicColors.prototype.secondaryFixedDim = function () {
            return MaterialDynamicColors.colorSpec.secondaryFixedDim();
        };
        MaterialDynamicColors.prototype.onSecondaryFixed = function () {
            return MaterialDynamicColors.colorSpec.onSecondaryFixed();
        };
        MaterialDynamicColors.prototype.onSecondaryFixedVariant = function () {
            return MaterialDynamicColors.colorSpec.onSecondaryFixedVariant();
        };
        ////////////////////////////////////////////////////////////////
        // Tertiaries [T]                                             //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.tertiary = function () {
            return MaterialDynamicColors.colorSpec.tertiary();
        };
        MaterialDynamicColors.prototype.tertiaryDim = function () {
            return MaterialDynamicColors.colorSpec.tertiaryDim();
        };
        MaterialDynamicColors.prototype.onTertiary = function () {
            return MaterialDynamicColors.colorSpec.onTertiary();
        };
        MaterialDynamicColors.prototype.tertiaryContainer = function () {
            return MaterialDynamicColors.colorSpec.tertiaryContainer();
        };
        MaterialDynamicColors.prototype.onTertiaryContainer = function () {
            return MaterialDynamicColors.colorSpec.onTertiaryContainer();
        };
        /////////////////////////////////////////////////////////////////
        // Tertiary Fixed [TF]                                         //
        /////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.tertiaryFixed = function () {
            return MaterialDynamicColors.colorSpec.tertiaryFixed();
        };
        MaterialDynamicColors.prototype.tertiaryFixedDim = function () {
            return MaterialDynamicColors.colorSpec.tertiaryFixedDim();
        };
        MaterialDynamicColors.prototype.onTertiaryFixed = function () {
            return MaterialDynamicColors.colorSpec.onTertiaryFixed();
        };
        MaterialDynamicColors.prototype.onTertiaryFixedVariant = function () {
            return MaterialDynamicColors.colorSpec.onTertiaryFixedVariant();
        };
        ////////////////////////////////////////////////////////////////
        // Errors [E]                                                 //
        ////////////////////////////////////////////////////////////////
        MaterialDynamicColors.prototype.error = function () {
            return MaterialDynamicColors.colorSpec.error();
        };
        MaterialDynamicColors.prototype.errorDim = function () {
            return MaterialDynamicColors.colorSpec.errorDim();
        };
        MaterialDynamicColors.prototype.onError = function () {
            return MaterialDynamicColors.colorSpec.onError();
        };
        MaterialDynamicColors.prototype.errorContainer = function () {
            return MaterialDynamicColors.colorSpec.errorContainer();
        };
        MaterialDynamicColors.prototype.onErrorContainer = function () {
            return MaterialDynamicColors.colorSpec.onErrorContainer();
        };
        // Static variables are deprecated. Use the instance methods to get correct
        // specs based on request.
        /** @deprecated Use highestSurface() instead. */
        MaterialDynamicColors.highestSurface = function (s) {
            return MaterialDynamicColors.colorSpec.highestSurface(s);
        };
        MaterialDynamicColors.contentAccentToneDelta = 15.0;
        MaterialDynamicColors.colorSpec = new ColorSpecDelegateImpl2025();
        /** @deprecated Use primaryPaletteKeyColor() instead. */
        MaterialDynamicColors.primaryPaletteKeyColor = MaterialDynamicColors.colorSpec.primaryPaletteKeyColor();
        /** @deprecated Use secondaryPaletteKeyColor() instead. */
        MaterialDynamicColors.secondaryPaletteKeyColor = MaterialDynamicColors.colorSpec.secondaryPaletteKeyColor();
        /** @deprecated Use tertiaryPaletteKeyColor() instead. */
        MaterialDynamicColors.tertiaryPaletteKeyColor = MaterialDynamicColors.colorSpec.tertiaryPaletteKeyColor();
        /** @deprecated Use neutralPaletteKeyColor() instead. */
        MaterialDynamicColors.neutralPaletteKeyColor = MaterialDynamicColors.colorSpec.neutralPaletteKeyColor();
        /** @deprecated Use neutralVariantPaletteKeyColor() instead. */
        MaterialDynamicColors.neutralVariantPaletteKeyColor = MaterialDynamicColors.colorSpec.neutralVariantPaletteKeyColor();
        /** @deprecated Use background() instead. */
        MaterialDynamicColors.background = MaterialDynamicColors.colorSpec.background();
        /** @deprecated Use background() instead. */
        MaterialDynamicColors.onBackground = MaterialDynamicColors.colorSpec.onBackground();
        /** @deprecated Use surface() instead. */
        MaterialDynamicColors.surface = MaterialDynamicColors.colorSpec.surface();
        /** @deprecated Use surfaceDim() instead. */
        MaterialDynamicColors.surfaceDim = MaterialDynamicColors.colorSpec.surfaceDim();
        /** @deprecated Use surfaceBright() instead. */
        MaterialDynamicColors.surfaceBright = MaterialDynamicColors.colorSpec.surfaceBright();
        /** @deprecated Use surfaceContainerLowest() instead. */
        MaterialDynamicColors.surfaceContainerLowest = MaterialDynamicColors.colorSpec.surfaceContainerLowest();
        /** @deprecated Use surfaceContainerLow() instead. */
        MaterialDynamicColors.surfaceContainerLow = MaterialDynamicColors.colorSpec.surfaceContainerLow();
        /** @deprecated Use surfaceContainer() instead. */
        MaterialDynamicColors.surfaceContainer = MaterialDynamicColors.colorSpec.surfaceContainer();
        /** @deprecated Use surfaceContainerHigh() instead. */
        MaterialDynamicColors.surfaceContainerHigh = MaterialDynamicColors.colorSpec.surfaceContainerHigh();
        /** @deprecated Use surfaceContainerHighest() instead. */
        MaterialDynamicColors.surfaceContainerHighest = MaterialDynamicColors.colorSpec.surfaceContainerHighest();
        /** @deprecated Use onSurface() instead. */
        MaterialDynamicColors.onSurface = MaterialDynamicColors.colorSpec.onSurface();
        /** @deprecated Use surfaceVariant() instead. */
        MaterialDynamicColors.surfaceVariant = MaterialDynamicColors.colorSpec.surfaceVariant();
        /** @deprecated Use onSurfaceVariant() instead. */
        MaterialDynamicColors.onSurfaceVariant = MaterialDynamicColors.colorSpec.onSurfaceVariant();
        /** @deprecated Use inverseSurface() instead. */
        MaterialDynamicColors.inverseSurface = MaterialDynamicColors.colorSpec.inverseSurface();
        /** @deprecated Use inverseOnSurface() instead. */
        MaterialDynamicColors.inverseOnSurface = MaterialDynamicColors.colorSpec.inverseOnSurface();
        /** @deprecated Use outline() instead. */
        MaterialDynamicColors.outline = MaterialDynamicColors.colorSpec.outline();
        /** @deprecated Use outlineVariant() instead. */
        MaterialDynamicColors.outlineVariant = MaterialDynamicColors.colorSpec.outlineVariant();
        /** @deprecated Use shadow() instead. */
        MaterialDynamicColors.shadow = MaterialDynamicColors.colorSpec.shadow();
        /** @deprecated Use scrim() instead. */
        MaterialDynamicColors.scrim = MaterialDynamicColors.colorSpec.scrim();
        /** @deprecated Use surfaceTint() instead. */
        MaterialDynamicColors.surfaceTint = MaterialDynamicColors.colorSpec.surfaceTint();
        /** @deprecated Use primary() instead. */
        MaterialDynamicColors.primary = MaterialDynamicColors.colorSpec.primary();
        /** @deprecated Use onPrimary() instead. */
        MaterialDynamicColors.onPrimary = MaterialDynamicColors.colorSpec.onPrimary();
        /** @deprecated Use primaryContainer() instead. */
        MaterialDynamicColors.primaryContainer = MaterialDynamicColors.colorSpec.primaryContainer();
        /** @deprecated Use onPrimaryContainer() instead. */
        MaterialDynamicColors.onPrimaryContainer = MaterialDynamicColors.colorSpec.onPrimaryContainer();
        /** @deprecated Use inversePrimary() instead. */
        MaterialDynamicColors.inversePrimary = MaterialDynamicColors.colorSpec.inversePrimary();
        /** @deprecated Use secondary() instead. */
        MaterialDynamicColors.secondary = MaterialDynamicColors.colorSpec.secondary();
        /** @deprecated Use onSecondary() instead. */
        MaterialDynamicColors.onSecondary = MaterialDynamicColors.colorSpec.onSecondary();
        /** @deprecated Use secondaryContainer() instead. */
        MaterialDynamicColors.secondaryContainer = MaterialDynamicColors.colorSpec.secondaryContainer();
        /** @deprecated Use onSecondaryContainer() instead. */
        MaterialDynamicColors.onSecondaryContainer = MaterialDynamicColors.colorSpec.onSecondaryContainer();
        /** @deprecated Use tertiary() instead. */
        MaterialDynamicColors.tertiary = MaterialDynamicColors.colorSpec.tertiary();
        /** @deprecated Use onTertiary() instead. */
        MaterialDynamicColors.onTertiary = MaterialDynamicColors.colorSpec.onTertiary();
        /** @deprecated Use tertiaryContainer() instead. */
        MaterialDynamicColors.tertiaryContainer = MaterialDynamicColors.colorSpec.tertiaryContainer();
        /** @deprecated Use onTertiaryContainer() instead. */
        MaterialDynamicColors.onTertiaryContainer = MaterialDynamicColors.colorSpec.onTertiaryContainer();
        /** @deprecated Use error() instead. */
        MaterialDynamicColors.error = MaterialDynamicColors.colorSpec.error();
        /** @deprecated Use onError() instead. */
        MaterialDynamicColors.onError = MaterialDynamicColors.colorSpec.onError();
        /** @deprecated Use errorContainer() instead. */
        MaterialDynamicColors.errorContainer = MaterialDynamicColors.colorSpec.errorContainer();
        /** @deprecated Use onErrorContainer() instead. */
        MaterialDynamicColors.onErrorContainer = MaterialDynamicColors.colorSpec.onErrorContainer();
        /** @deprecated Use primaryFixed() instead. */
        MaterialDynamicColors.primaryFixed = MaterialDynamicColors.colorSpec.primaryFixed();
        /** @deprecated Use primaryFixedDim() instead. */
        MaterialDynamicColors.primaryFixedDim = MaterialDynamicColors.colorSpec.primaryFixedDim();
        /** @deprecated Use onPrimaryFixed() instead. */
        MaterialDynamicColors.onPrimaryFixed = MaterialDynamicColors.colorSpec.onPrimaryFixed();
        /** @deprecated Use onPrimaryFixedVariant() instead. */
        MaterialDynamicColors.onPrimaryFixedVariant = MaterialDynamicColors.colorSpec.onPrimaryFixedVariant();
        /** @deprecated Use secondaryFixed() instead. */
        MaterialDynamicColors.secondaryFixed = MaterialDynamicColors.colorSpec.secondaryFixed();
        /** @deprecated Use secondaryFixedDim() instead. */
        MaterialDynamicColors.secondaryFixedDim = MaterialDynamicColors.colorSpec.secondaryFixedDim();
        /** @deprecated Use onSecondaryFixed() instead. */
        MaterialDynamicColors.onSecondaryFixed = MaterialDynamicColors.colorSpec.onSecondaryFixed();
        /** @deprecated Use onSecondaryFixedVariant() instead. */
        MaterialDynamicColors.onSecondaryFixedVariant = MaterialDynamicColors.colorSpec.onSecondaryFixedVariant();
        /** @deprecated Use tertiaryFixed() instead. */
        MaterialDynamicColors.tertiaryFixed = MaterialDynamicColors.colorSpec.tertiaryFixed();
        /** @deprecated Use tertiaryFixedDim() instead. */
        MaterialDynamicColors.tertiaryFixedDim = MaterialDynamicColors.colorSpec.tertiaryFixedDim();
        /** @deprecated Use onTertiaryFixed() instead. */
        MaterialDynamicColors.onTertiaryFixed = MaterialDynamicColors.colorSpec.onTertiaryFixed();
        /** @deprecated Use onTertiaryFixedVariant() instead. */
        MaterialDynamicColors.onTertiaryFixedVariant = MaterialDynamicColors.colorSpec.onTertiaryFixedVariant();
        return MaterialDynamicColors;
    }());

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Constructed by a set of values representing the current UI state (such as
     * whether or not its dark theme, what the theme style is, etc.), and
     * provides a set of TonalPalettes that can create colors that fit in
     * with the theme style. Used by DynamicColor to resolve into a color.
     */
    var DynamicScheme = /** @class */ (function () {
        function DynamicScheme(args) {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j;
            this.sourceColorArgb = args.sourceColorHct.toInt();
            this.variant = args.variant;
            this.contrastLevel = args.contrastLevel;
            this.isDark = args.isDark;
            this.platform = (_a = args.platform) !== null && _a !== void 0 ? _a : 'phone';
            this.specVersion = DynamicScheme.maybeFallbackSpecVersion((_b = args.specVersion) !== null && _b !== void 0 ? _b : '2021', this.variant);
            this.sourceColorHct = args.sourceColorHct;
            this.primaryPalette = (_c = args.primaryPalette) !== null && _c !== void 0 ? _c : getSpec(this.specVersion)
                .getPrimaryPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel);
            this.secondaryPalette = (_d = args.secondaryPalette) !== null && _d !== void 0 ? _d : getSpec(this.specVersion)
                .getSecondaryPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel);
            this.tertiaryPalette = (_e = args.tertiaryPalette) !== null && _e !== void 0 ? _e : getSpec(this.specVersion)
                .getTertiaryPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel);
            this.neutralPalette = (_f = args.neutralPalette) !== null && _f !== void 0 ? _f : getSpec(this.specVersion)
                .getNeutralPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel);
            this.neutralVariantPalette = (_g = args.neutralVariantPalette) !== null && _g !== void 0 ? _g : getSpec(this.specVersion)
                .getNeutralVariantPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel);
            this.errorPalette = (_j = (_h = args.errorPalette) !== null && _h !== void 0 ? _h : getSpec(this.specVersion)
                .getErrorPalette(this.variant, args.sourceColorHct, this.isDark, this.platform, this.contrastLevel)) !== null && _j !== void 0 ? _j : TonalPalette.fromHueAndChroma(25.0, 84.0);
            this.colors = new MaterialDynamicColors();
        }
        DynamicScheme.maybeFallbackSpecVersion = function (specVersion, variant) {
            switch (variant) {
                case exports.Variant.EXPRESSIVE:
                case exports.Variant.VIBRANT:
                case exports.Variant.TONAL_SPOT:
                case exports.Variant.NEUTRAL:
                    return specVersion;
                default:
                    return '2021';
            }
        };
        DynamicScheme.prototype.toString = function () {
            return "Scheme: " +
                "variant=".concat(exports.Variant[this.variant], ", ") +
                "mode=".concat(this.isDark ? 'dark' : 'light', ", ") +
                "platform=".concat(this.platform, ", ") +
                "contrastLevel=".concat(this.contrastLevel.toFixed(1), ", ") +
                "seed=".concat(this.sourceColorHct.toString(), ", ") +
                "specVersion=".concat(this.specVersion);
        };
        /**
         * Returns a new hue based on a piecewise function and input color hue.
         *
         * For example, for the following function:
         * result = 26 if 0 <= hue < 101
         * result = 39 if 101 <= hue < 210
         * result = 28 if 210 <= hue < 360
         *
         * call the function as:
         *
         * const hueBreakpoints = [0, 101, 210, 360];
         * const hues = [26, 39, 28];
         * const result = scheme.piecewise(hue, hueBreakpoints, hues);
         *
         * @param sourceColorHct The input value.
         * @param hueBreakpoints The breakpoints, in sorted order. No default lower or
         *     upper bounds are assumed.
         * @param hues The hues that should be applied when source color's hue is >=
         *     the same index in hueBrakpoints array, and < the hue at the next index
         *     in hueBrakpoints array. Otherwise, the source color's hue is returned.
         */
        DynamicScheme.getPiecewiseHue = function (sourceColorHct, hueBreakpoints, hues) {
            var size = Math.min(hueBreakpoints.length - 1, hues.length);
            var sourceHue = sourceColorHct.hue;
            for (var i = 0; i < size; i++) {
                if (sourceHue >= hueBreakpoints[i] && sourceHue < hueBreakpoints[i + 1]) {
                    return sanitizeDegreesDouble(hues[i]);
                }
            }
            // No condition matched, return the source hue.
            return sourceHue;
        };
        /**
         * Returns a shifted hue based on a piecewise function and input color hue.
         *
         * For example, for the following function:
         * result = hue + 26 if 0 <= hue < 101
         * result = hue - 39 if 101 <= hue < 210
         * result = hue + 28 if 210 <= hue < 360
         *
         * call the function as:
         *
         * const hueBreakpoints = [0, 101, 210, 360];
         * const hues = [26, -39, 28];
         * const result = scheme.getRotatedHue(hue, hueBreakpoints, hues);
         *
         * @param sourceColorHct the source color of the theme, in HCT.
         * @param hueBreakpoints The "breakpoints", i.e. the hues at which a rotation
         *     should be apply. No default lower or upper bounds are assumed.
         * @param rotations The rotation that should be applied when source color's
         *     hue is >= the same index in hues array, and < the hue at the next
         *     index in hues array. Otherwise, the source color's hue is returned.
         */
        DynamicScheme.getRotatedHue = function (sourceColorHct, hueBreakpoints, rotations) {
            var rotation = DynamicScheme.getPiecewiseHue(sourceColorHct, hueBreakpoints, rotations);
            if (Math.min(hueBreakpoints.length - 1, rotations.length) <= 0) {
                // No condition matched, return the source hue.
                rotation = 0;
            }
            return sanitizeDegreesDouble(sourceColorHct.hue + rotation);
        };
        DynamicScheme.prototype.getArgb = function (dynamicColor) {
            return dynamicColor.getArgb(this);
        };
        DynamicScheme.prototype.getHct = function (dynamicColor) {
            return dynamicColor.getHct(this);
        };
        Object.defineProperty(DynamicScheme.prototype, "primaryPaletteKeyColor", {
            // Palette key colors
            get: function () {
                return this.getArgb(this.colors.primaryPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondaryPaletteKeyColor", {
            get: function () {
                return this.getArgb(this.colors.secondaryPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiaryPaletteKeyColor", {
            get: function () {
                return this.getArgb(this.colors.tertiaryPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "neutralPaletteKeyColor", {
            get: function () {
                return this.getArgb(this.colors.neutralPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "neutralVariantPaletteKeyColor", {
            get: function () {
                return this.getArgb(this.colors.neutralVariantPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "errorPaletteKeyColor", {
            get: function () {
                return this.getArgb(this.colors.errorPaletteKeyColor());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "background", {
            // Surface colors
            get: function () {
                return this.getArgb(this.colors.background());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onBackground", {
            get: function () {
                return this.getArgb(this.colors.onBackground());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surface", {
            get: function () {
                return this.getArgb(this.colors.surface());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceDim", {
            get: function () {
                return this.getArgb(this.colors.surfaceDim());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceBright", {
            get: function () {
                return this.getArgb(this.colors.surfaceBright());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceContainerLowest", {
            get: function () {
                return this.getArgb(this.colors.surfaceContainerLowest());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceContainerLow", {
            get: function () {
                return this.getArgb(this.colors.surfaceContainerLow());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceContainer", {
            get: function () {
                return this.getArgb(this.colors.surfaceContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceContainerHigh", {
            get: function () {
                return this.getArgb(this.colors.surfaceContainerHigh());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceContainerHighest", {
            get: function () {
                return this.getArgb(this.colors.surfaceContainerHighest());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSurface", {
            get: function () {
                return this.getArgb(this.colors.onSurface());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceVariant", {
            get: function () {
                return this.getArgb(this.colors.surfaceVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSurfaceVariant", {
            get: function () {
                return this.getArgb(this.colors.onSurfaceVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "inverseSurface", {
            get: function () {
                return this.getArgb(this.colors.inverseSurface());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "inverseOnSurface", {
            get: function () {
                return this.getArgb(this.colors.inverseOnSurface());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "outline", {
            get: function () {
                return this.getArgb(this.colors.outline());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "outlineVariant", {
            get: function () {
                return this.getArgb(this.colors.outlineVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "shadow", {
            get: function () {
                return this.getArgb(this.colors.shadow());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "scrim", {
            get: function () {
                return this.getArgb(this.colors.scrim());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "surfaceTint", {
            get: function () {
                return this.getArgb(this.colors.surfaceTint());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "primary", {
            // Primary colors
            get: function () {
                return this.getArgb(this.colors.primary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "primaryDim", {
            get: function () {
                var primaryDim = this.colors.primaryDim();
                if (primaryDim === undefined) {
                    throw new Error('`primaryDim` color is undefined prior to 2025 spec.');
                }
                return this.getArgb(primaryDim);
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onPrimary", {
            get: function () {
                return this.getArgb(this.colors.onPrimary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "primaryContainer", {
            get: function () {
                return this.getArgb(this.colors.primaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onPrimaryContainer", {
            get: function () {
                return this.getArgb(this.colors.onPrimaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "primaryFixed", {
            get: function () {
                return this.getArgb(this.colors.primaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "primaryFixedDim", {
            get: function () {
                return this.getArgb(this.colors.primaryFixedDim());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onPrimaryFixed", {
            get: function () {
                return this.getArgb(this.colors.onPrimaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onPrimaryFixedVariant", {
            get: function () {
                return this.getArgb(this.colors.onPrimaryFixedVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "inversePrimary", {
            get: function () {
                return this.getArgb(this.colors.inversePrimary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondary", {
            // Secondary colors
            get: function () {
                return this.getArgb(this.colors.secondary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondaryDim", {
            get: function () {
                var secondaryDim = this.colors.secondaryDim();
                if (secondaryDim === undefined) {
                    throw new Error('`secondaryDim` color is undefined prior to 2025 spec.');
                }
                return this.getArgb(secondaryDim);
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSecondary", {
            get: function () {
                return this.getArgb(this.colors.onSecondary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondaryContainer", {
            get: function () {
                return this.getArgb(this.colors.secondaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSecondaryContainer", {
            get: function () {
                return this.getArgb(this.colors.onSecondaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondaryFixed", {
            get: function () {
                return this.getArgb(this.colors.secondaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "secondaryFixedDim", {
            get: function () {
                return this.getArgb(this.colors.secondaryFixedDim());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSecondaryFixed", {
            get: function () {
                return this.getArgb(this.colors.onSecondaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onSecondaryFixedVariant", {
            get: function () {
                return this.getArgb(this.colors.onSecondaryFixedVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiary", {
            // Tertiary colors
            get: function () {
                return this.getArgb(this.colors.tertiary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiaryDim", {
            get: function () {
                var tertiaryDim = this.colors.tertiaryDim();
                if (tertiaryDim === undefined) {
                    throw new Error('`tertiaryDim` color is undefined prior to 2025 spec.');
                }
                return this.getArgb(tertiaryDim);
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onTertiary", {
            get: function () {
                return this.getArgb(this.colors.onTertiary());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiaryContainer", {
            get: function () {
                return this.getArgb(this.colors.tertiaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onTertiaryContainer", {
            get: function () {
                return this.getArgb(this.colors.onTertiaryContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiaryFixed", {
            get: function () {
                return this.getArgb(this.colors.tertiaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "tertiaryFixedDim", {
            get: function () {
                return this.getArgb(this.colors.tertiaryFixedDim());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onTertiaryFixed", {
            get: function () {
                return this.getArgb(this.colors.onTertiaryFixed());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onTertiaryFixedVariant", {
            get: function () {
                return this.getArgb(this.colors.onTertiaryFixedVariant());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "error", {
            // Error colors
            get: function () {
                return this.getArgb(this.colors.error());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "errorDim", {
            get: function () {
                var errorDim = this.colors.errorDim();
                if (errorDim === undefined) {
                    throw new Error('`errorDim` color is undefined prior to 2025 spec.');
                }
                return this.getArgb(errorDim);
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onError", {
            get: function () {
                return this.getArgb(this.colors.onError());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "errorContainer", {
            get: function () {
                return this.getArgb(this.colors.errorContainer());
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(DynamicScheme.prototype, "onErrorContainer", {
            get: function () {
                return this.getArgb(this.colors.onErrorContainer());
            },
            enumerable: false,
            configurable: true
        });
        DynamicScheme.DEFAULT_SPEC_VERSION = '2021';
        DynamicScheme.DEFAULT_PLATFORM = 'phone';
        return DynamicScheme;
    }());
    /**
     * A delegate for the palettes of a DynamicScheme in the 2021 spec.
     */
    var DynamicSchemePalettesDelegateImpl2021 = /** @class */ (function () {
        function DynamicSchemePalettesDelegateImpl2021() {
        }
        //////////////////////////////////////////////////////////////////
        // Scheme Palettes                                              //
        //////////////////////////////////////////////////////////////////
        DynamicSchemePalettesDelegateImpl2021.prototype.getPrimaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.CONTENT:
                case exports.Variant.FIDELITY:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, sourceColorHct.chroma);
                case exports.Variant.FRUIT_SALAD:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue - 50.0), 48.0);
                case exports.Variant.MONOCHROME:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 12.0);
                case exports.Variant.RAINBOW:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 48.0);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 36.0);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue + 240), 40);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 200.0);
                default:
                    throw new Error("Unsupported variant: ".concat(variant));
            }
        };
        DynamicSchemePalettesDelegateImpl2021.prototype.getSecondaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.CONTENT:
                case exports.Variant.FIDELITY:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, Math.max(sourceColorHct.chroma - 32.0, sourceColorHct.chroma * 0.5));
                case exports.Variant.FRUIT_SALAD:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue - 50.0), 36.0);
                case exports.Variant.MONOCHROME:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 8.0);
                case exports.Variant.RAINBOW:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 16.0);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 16.0);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 21, 51, 121, 151, 191, 271, 321, 360], [45, 95, 45, 20, 45, 90, 45, 45, 45]), 24.0);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 41, 61, 101, 131, 181, 251, 301, 360], [18, 15, 10, 12, 15, 18, 15, 12, 12]), 24.0);
                default:
                    throw new Error("Unsupported variant: ".concat(variant));
            }
        };
        DynamicSchemePalettesDelegateImpl2021.prototype.getTertiaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.CONTENT:
                    return TonalPalette.fromHct(DislikeAnalyzer.fixIfDisliked(new TemperatureCache(sourceColorHct)
                        .analogous(/* count= */ 3, /* divisions= */ 6)[2]));
                case exports.Variant.FIDELITY:
                    return TonalPalette.fromHct(DislikeAnalyzer.fixIfDisliked(new TemperatureCache(sourceColorHct).complement));
                case exports.Variant.FRUIT_SALAD:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 36.0);
                case exports.Variant.MONOCHROME:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 16.0);
                case exports.Variant.RAINBOW:
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue + 60.0), 24.0);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 21, 51, 121, 151, 191, 271, 321, 360], [120, 120, 20, 45, 20, 15, 20, 120, 120]), 32.0);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 41, 61, 101, 131, 181, 251, 301, 360], [35, 30, 20, 25, 30, 35, 30, 25, 25]), 32.0);
                default:
                    throw new Error("Unsupported variant: ".concat(variant));
            }
        };
        DynamicSchemePalettesDelegateImpl2021.prototype.getNeutralPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.CONTENT:
                case exports.Variant.FIDELITY:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, sourceColorHct.chroma / 8.0);
                case exports.Variant.FRUIT_SALAD:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 10.0);
                case exports.Variant.MONOCHROME:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 2.0);
                case exports.Variant.RAINBOW:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 6.0);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue + 15), 8);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 10);
                default:
                    throw new Error("Unsupported variant: ".concat(variant));
            }
        };
        DynamicSchemePalettesDelegateImpl2021.prototype.getNeutralVariantPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.CONTENT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, (sourceColorHct.chroma / 8.0) + 4.0);
                case exports.Variant.FIDELITY:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, (sourceColorHct.chroma / 8.0) + 4.0);
                case exports.Variant.FRUIT_SALAD:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 16.0);
                case exports.Variant.MONOCHROME:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 2.0);
                case exports.Variant.RAINBOW:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 0.0);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 8.0);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(sanitizeDegreesDouble(sourceColorHct.hue + 15), 12);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 12);
                default:
                    throw new Error("Unsupported variant: ".concat(variant));
            }
        };
        DynamicSchemePalettesDelegateImpl2021.prototype.getErrorPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            return undefined;
        };
        return DynamicSchemePalettesDelegateImpl2021;
    }());
    /**
     * A delegate for the palettes of a DynamicScheme in the 2025 spec.
     */
    var DynamicSchemePalettesDelegateImpl2025 = /** @class */ (function (_super) {
        __extends(DynamicSchemePalettesDelegateImpl2025, _super);
        function DynamicSchemePalettesDelegateImpl2025() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        //////////////////////////////////////////////////////////////////
        // Scheme Palettes                                              //
        //////////////////////////////////////////////////////////////////
        DynamicSchemePalettesDelegateImpl2025.prototype.getPrimaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? (Hct.isBlue(sourceColorHct.hue) ? 12 : 8) :
                        (Hct.isBlue(sourceColorHct.hue) ? 16 : 12));
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' && isDark ? 26 : 32);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? (isDark ? 36 : 48) : 40);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? 74 : 56);
                default:
                    return _super.prototype.getPrimaryPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        DynamicSchemePalettesDelegateImpl2025.prototype.getSecondaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? (Hct.isBlue(sourceColorHct.hue) ? 6 : 4) :
                        (Hct.isBlue(sourceColorHct.hue) ? 10 : 6));
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, 16);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 105, 140, 204, 253, 278, 300, 333, 360], [-160, 155, -100, 96, -96, -156, -165, -160]), platform === 'phone' ? (isDark ? 16 : 24) : 24);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 38, 105, 140, 333, 360], [-14, 10, -14, 10, -14]), platform === 'phone' ? 56 : 36);
                default:
                    return _super.prototype.getSecondaryPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        DynamicSchemePalettesDelegateImpl2025.prototype.getTertiaryPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 38, 105, 161, 204, 278, 333, 360], [-32, 26, 10, -39, 24, -15, -32]), platform === 'phone' ? 20 : 36);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 20, 71, 161, 333, 360], [-40, 48, -32, 40, -32]), platform === 'phone' ? 28 : 32);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 105, 140, 204, 253, 278, 300, 333, 360], [-165, 160, -105, 101, -101, -160, -170, -165]), 48);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(DynamicScheme.getRotatedHue(sourceColorHct, [0, 38, 71, 105, 140, 161, 253, 333, 360], [-72, 35, 24, -24, 62, 50, 62, -72]), 56);
                default:
                    return _super.prototype.getTertiaryPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralHue = function (sourceColorHct) {
            var hue = DynamicScheme.getRotatedHue(sourceColorHct, [0, 71, 124, 253, 278, 300, 360], [10, 0, 10, 0, 10, 0]);
            return hue;
        };
        DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralChroma = function (sourceColorHct, isDark, platform) {
            var neutralHue = DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralHue(sourceColorHct);
            return platform === 'phone' ?
                (isDark ? (Hct.isYellow(neutralHue) ? 6 : 14) : 18) :
                12;
        };
        DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralHue = function (sourceColorHct) {
            return DynamicScheme.getRotatedHue(sourceColorHct, [0, 38, 105, 140, 333, 360], [-14, 10, -14, 10, -14]);
        };
        DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralChroma = function (sourceColorHct, platform) {
            var neutralHue = DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralHue(sourceColorHct);
            return platform === 'phone' ? 28 : (Hct.isBlue(neutralHue) ? 28 : 20);
        };
        DynamicSchemePalettesDelegateImpl2025.prototype.getNeutralPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? 1.4 : 6);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, platform === 'phone' ? 5 : 10);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralHue(sourceColorHct), DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralChroma(sourceColorHct, isDark, platform));
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralHue(sourceColorHct), DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralChroma(sourceColorHct, platform));
                default:
                    return _super.prototype.getNeutralPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        DynamicSchemePalettesDelegateImpl2025.prototype.getNeutralVariantPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, (platform === 'phone' ? 1.4 : 6) * 2.2);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(sourceColorHct.hue, (platform === 'phone' ? 5 : 10) * 1.7);
                case exports.Variant.EXPRESSIVE:
                    var expressiveNeutralHue = DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralHue(sourceColorHct);
                    var expressiveNeutralChroma = DynamicSchemePalettesDelegateImpl2025.getExpressiveNeutralChroma(sourceColorHct, isDark, platform);
                    return TonalPalette.fromHueAndChroma(expressiveNeutralHue, expressiveNeutralChroma *
                        (expressiveNeutralHue >= 105 && expressiveNeutralHue < 125 ?
                            1.6 :
                            2.3));
                case exports.Variant.VIBRANT:
                    var vibrantNeutralHue = DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralHue(sourceColorHct);
                    var vibrantNeutralChroma = DynamicSchemePalettesDelegateImpl2025.getVibrantNeutralChroma(sourceColorHct, platform);
                    return TonalPalette.fromHueAndChroma(vibrantNeutralHue, vibrantNeutralChroma * 1.29);
                default:
                    return _super.prototype.getNeutralVariantPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        DynamicSchemePalettesDelegateImpl2025.prototype.getErrorPalette = function (variant, sourceColorHct, isDark, platform, contrastLevel) {
            var errorHue = DynamicScheme.getPiecewiseHue(sourceColorHct, [0, 3, 13, 23, 33, 43, 153, 273, 360], [12, 22, 32, 12, 22, 32, 22, 12]);
            switch (variant) {
                case exports.Variant.NEUTRAL:
                    return TonalPalette.fromHueAndChroma(errorHue, platform === 'phone' ? 50 : 40);
                case exports.Variant.TONAL_SPOT:
                    return TonalPalette.fromHueAndChroma(errorHue, platform === 'phone' ? 60 : 48);
                case exports.Variant.EXPRESSIVE:
                    return TonalPalette.fromHueAndChroma(errorHue, platform === 'phone' ? 64 : 48);
                case exports.Variant.VIBRANT:
                    return TonalPalette.fromHueAndChroma(errorHue, platform === 'phone' ? 80 : 60);
                default:
                    return _super.prototype.getErrorPalette.call(this, variant, sourceColorHct, isDark, platform, contrastLevel);
            }
        };
        return DynamicSchemePalettesDelegateImpl2025;
    }(DynamicSchemePalettesDelegateImpl2021));
    var spec2021 = new DynamicSchemePalettesDelegateImpl2021();
    var spec2025 = new DynamicSchemePalettesDelegateImpl2025();
    /**
     * Returns the DynamicSchemePalettesDelegate for the given spec version.
     */
    function getSpec(specVersion) {
        return specVersion === '2025' ? spec2025 : spec2021;
    }

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * An intermediate concept between the key color for a UI theme, and a full
     * color scheme. 5 sets of tones are generated, all except one use the same hue
     * as the key color, and all vary in chroma.
     *
     * @deprecated Use {@link DynamicScheme} for color scheme generation.
     * Use {@link CorePalettes} for core palettes container class.
     */
    var CorePalette = /** @class */ (function () {
        function CorePalette(argb, isContent) {
            var hct = Hct.fromInt(argb);
            var hue = hct.hue;
            var chroma = hct.chroma;
            if (isContent) {
                this.a1 = TonalPalette.fromHueAndChroma(hue, chroma);
                this.a2 = TonalPalette.fromHueAndChroma(hue, chroma / 3);
                this.a3 = TonalPalette.fromHueAndChroma(hue + 60, chroma / 2);
                this.n1 = TonalPalette.fromHueAndChroma(hue, Math.min(chroma / 12, 4));
                this.n2 = TonalPalette.fromHueAndChroma(hue, Math.min(chroma / 6, 8));
            }
            else {
                this.a1 = TonalPalette.fromHueAndChroma(hue, Math.max(48, chroma));
                this.a2 = TonalPalette.fromHueAndChroma(hue, 16);
                this.a3 = TonalPalette.fromHueAndChroma(hue + 60, 24);
                this.n1 = TonalPalette.fromHueAndChroma(hue, 4);
                this.n2 = TonalPalette.fromHueAndChroma(hue, 8);
            }
            this.error = TonalPalette.fromHueAndChroma(25, 84);
        }
        /**
         * @param argb ARGB representation of a color
         *
         * @deprecated Use {@link DynamicScheme} for color scheme generation.
         * Use {@link CorePalettes} for core palettes container class.
         */
        CorePalette.of = function (argb) {
            return new CorePalette(argb, false);
        };
        /**
         * @param argb ARGB representation of a color
         *
         * @deprecated Use {@link DynamicScheme} for color scheme generation.
         * Use {@link CorePalettes} for core palettes container class.
         */
        CorePalette.contentOf = function (argb) {
            return new CorePalette(argb, true);
        };
        /**
         * Create a [CorePalette] from a set of colors
         *
         * @deprecated Use {@link DynamicScheme} for color scheme generation.
         * Use {@link CorePalettes} for core palettes container class.
         */
        CorePalette.fromColors = function (colors) {
            return CorePalette.createPaletteFromColors(false, colors);
        };
        /**
         * Create a content [CorePalette] from a set of colors
         *
         * @deprecated Use {@link DynamicScheme} for color scheme generation.
         * Use {@link CorePalettes} for core palettes container class.
         */
        CorePalette.contentFromColors = function (colors) {
            return CorePalette.createPaletteFromColors(true, colors);
        };
        CorePalette.createPaletteFromColors = function (content, colors) {
            var palette = new CorePalette(colors.primary, content);
            if (colors.secondary) {
                var p = new CorePalette(colors.secondary, content);
                palette.a2 = p.a1;
            }
            if (colors.tertiary) {
                var p = new CorePalette(colors.tertiary, content);
                palette.a3 = p.a1;
            }
            if (colors.error) {
                var p = new CorePalette(colors.error, content);
                palette.error = p.a1;
            }
            if (colors.neutral) {
                var p = new CorePalette(colors.neutral, content);
                palette.n1 = p.n1;
            }
            if (colors.neutralVariant) {
                var p = new CorePalette(colors.neutralVariant, content);
                palette.n2 = p.n2;
            }
            return palette;
        };
        return CorePalette;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * DEPRECATED. The `Scheme` class is deprecated in favor of `DynamicScheme`.
     * Please see
     * https://github.com/material-foundation/material-color-utilities/blob/main/make_schemes.md
     * for migration guidance.
     *
     * Represents a Material color scheme, a mapping of color roles to colors.
     */
    var Scheme = /** @class */ (function () {
        function Scheme(props) {
            this.props = props;
        }
        Object.defineProperty(Scheme.prototype, "primary", {
            get: function () {
                return this.props.primary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onPrimary", {
            get: function () {
                return this.props.onPrimary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "primaryContainer", {
            get: function () {
                return this.props.primaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onPrimaryContainer", {
            get: function () {
                return this.props.onPrimaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "secondary", {
            get: function () {
                return this.props.secondary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onSecondary", {
            get: function () {
                return this.props.onSecondary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "secondaryContainer", {
            get: function () {
                return this.props.secondaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onSecondaryContainer", {
            get: function () {
                return this.props.onSecondaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "tertiary", {
            get: function () {
                return this.props.tertiary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onTertiary", {
            get: function () {
                return this.props.onTertiary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "tertiaryContainer", {
            get: function () {
                return this.props.tertiaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onTertiaryContainer", {
            get: function () {
                return this.props.onTertiaryContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "error", {
            get: function () {
                return this.props.error;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onError", {
            get: function () {
                return this.props.onError;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "errorContainer", {
            get: function () {
                return this.props.errorContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onErrorContainer", {
            get: function () {
                return this.props.onErrorContainer;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "background", {
            get: function () {
                return this.props.background;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onBackground", {
            get: function () {
                return this.props.onBackground;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "surface", {
            get: function () {
                return this.props.surface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onSurface", {
            get: function () {
                return this.props.onSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "surfaceVariant", {
            get: function () {
                return this.props.surfaceVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "onSurfaceVariant", {
            get: function () {
                return this.props.onSurfaceVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "outline", {
            get: function () {
                return this.props.outline;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "outlineVariant", {
            get: function () {
                return this.props.outlineVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "shadow", {
            get: function () {
                return this.props.shadow;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "scrim", {
            get: function () {
                return this.props.scrim;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "inverseSurface", {
            get: function () {
                return this.props.inverseSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "inverseOnSurface", {
            get: function () {
                return this.props.inverseOnSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(Scheme.prototype, "inversePrimary", {
            get: function () {
                return this.props.inversePrimary;
            },
            enumerable: false,
            configurable: true
        });
        /**
         * @param argb ARGB representation of a color.
         * @return Light Material color scheme, based on the color's hue.
         */
        Scheme.light = function (argb) {
            return Scheme.lightFromCorePalette(CorePalette.of(argb));
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Dark Material color scheme, based on the color's hue.
         */
        Scheme.dark = function (argb) {
            return Scheme.darkFromCorePalette(CorePalette.of(argb));
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Light Material content color scheme, based on the color's hue.
         */
        Scheme.lightContent = function (argb) {
            return Scheme.lightFromCorePalette(CorePalette.contentOf(argb));
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Dark Material content color scheme, based on the color's hue.
         */
        Scheme.darkContent = function (argb) {
            return Scheme.darkFromCorePalette(CorePalette.contentOf(argb));
        };
        /**
         * Light scheme from core palette
         */
        Scheme.lightFromCorePalette = function (core) {
            return new Scheme({
                primary: core.a1.tone(40),
                onPrimary: core.a1.tone(100),
                primaryContainer: core.a1.tone(90),
                onPrimaryContainer: core.a1.tone(10),
                secondary: core.a2.tone(40),
                onSecondary: core.a2.tone(100),
                secondaryContainer: core.a2.tone(90),
                onSecondaryContainer: core.a2.tone(10),
                tertiary: core.a3.tone(40),
                onTertiary: core.a3.tone(100),
                tertiaryContainer: core.a3.tone(90),
                onTertiaryContainer: core.a3.tone(10),
                error: core.error.tone(40),
                onError: core.error.tone(100),
                errorContainer: core.error.tone(90),
                onErrorContainer: core.error.tone(10),
                background: core.n1.tone(99),
                onBackground: core.n1.tone(10),
                surface: core.n1.tone(99),
                onSurface: core.n1.tone(10),
                surfaceVariant: core.n2.tone(90),
                onSurfaceVariant: core.n2.tone(30),
                outline: core.n2.tone(50),
                outlineVariant: core.n2.tone(80),
                shadow: core.n1.tone(0),
                scrim: core.n1.tone(0),
                inverseSurface: core.n1.tone(20),
                inverseOnSurface: core.n1.tone(95),
                inversePrimary: core.a1.tone(80)
            });
        };
        /**
         * Dark scheme from core palette
         */
        Scheme.darkFromCorePalette = function (core) {
            return new Scheme({
                primary: core.a1.tone(80),
                onPrimary: core.a1.tone(20),
                primaryContainer: core.a1.tone(30),
                onPrimaryContainer: core.a1.tone(90),
                secondary: core.a2.tone(80),
                onSecondary: core.a2.tone(20),
                secondaryContainer: core.a2.tone(30),
                onSecondaryContainer: core.a2.tone(90),
                tertiary: core.a3.tone(80),
                onTertiary: core.a3.tone(20),
                tertiaryContainer: core.a3.tone(30),
                onTertiaryContainer: core.a3.tone(90),
                error: core.error.tone(80),
                onError: core.error.tone(20),
                errorContainer: core.error.tone(30),
                onErrorContainer: core.error.tone(80),
                background: core.n1.tone(10),
                onBackground: core.n1.tone(90),
                surface: core.n1.tone(10),
                onSurface: core.n1.tone(90),
                surfaceVariant: core.n2.tone(30),
                onSurfaceVariant: core.n2.tone(80),
                outline: core.n2.tone(60),
                outlineVariant: core.n2.tone(30),
                shadow: core.n1.tone(0),
                scrim: core.n1.tone(0),
                inverseSurface: core.n1.tone(90),
                inverseOnSurface: core.n1.tone(20),
                inversePrimary: core.a1.tone(40)
            });
        };
        Scheme.prototype.toJSON = function () {
            return __assign({}, this.props);
        };
        return Scheme;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Represents an Android 12 color scheme, a mapping of color roles to colors.
     */
    var SchemeAndroid = /** @class */ (function () {
        function SchemeAndroid(props) {
            this.props = props;
        }
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentPrimary", {
            get: function () {
                return this.props.colorAccentPrimary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentPrimaryVariant", {
            get: function () {
                return this.props.colorAccentPrimaryVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentSecondary", {
            get: function () {
                return this.props.colorAccentSecondary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentSecondaryVariant", {
            get: function () {
                return this.props.colorAccentSecondaryVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentTertiary", {
            get: function () {
                return this.props.colorAccentTertiary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorAccentTertiaryVariant", {
            get: function () {
                return this.props.colorAccentTertiaryVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorPrimary", {
            get: function () {
                return this.props.textColorPrimary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorSecondary", {
            get: function () {
                return this.props.textColorSecondary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorTertiary", {
            get: function () {
                return this.props.textColorTertiary;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorPrimaryInverse", {
            get: function () {
                return this.props.textColorPrimaryInverse;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorSecondaryInverse", {
            get: function () {
                return this.props.textColorSecondaryInverse;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textColorTertiaryInverse", {
            get: function () {
                return this.props.textColorTertiaryInverse;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorBackground", {
            get: function () {
                return this.props.colorBackground;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorBackgroundFloating", {
            get: function () {
                return this.props.colorBackgroundFloating;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorSurface", {
            get: function () {
                return this.props.colorSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorSurfaceVariant", {
            get: function () {
                return this.props.colorSurfaceVariant;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "colorSurfaceHighlight", {
            get: function () {
                return this.props.colorSurfaceHighlight;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "surfaceHeader", {
            get: function () {
                return this.props.surfaceHeader;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "underSurface", {
            get: function () {
                return this.props.underSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "offState", {
            get: function () {
                return this.props.offState;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "accentSurface", {
            get: function () {
                return this.props.accentSurface;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textPrimaryOnAccent", {
            get: function () {
                return this.props.textPrimaryOnAccent;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "textSecondaryOnAccent", {
            get: function () {
                return this.props.textSecondaryOnAccent;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "volumeBackground", {
            get: function () {
                return this.props.volumeBackground;
            },
            enumerable: false,
            configurable: true
        });
        Object.defineProperty(SchemeAndroid.prototype, "scrim", {
            get: function () {
                return this.props.scrim;
            },
            enumerable: false,
            configurable: true
        });
        /**
         * @param argb ARGB representation of a color.
         * @return Light Material color scheme, based on the color's hue.
         */
        SchemeAndroid.light = function (argb) {
            var core = CorePalette.of(argb);
            return SchemeAndroid.lightFromCorePalette(core);
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Dark Material color scheme, based on the color's hue.
         */
        SchemeAndroid.dark = function (argb) {
            var core = CorePalette.of(argb);
            return SchemeAndroid.darkFromCorePalette(core);
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Light Android color scheme, based on the color's hue.
         */
        SchemeAndroid.lightContent = function (argb) {
            var core = CorePalette.contentOf(argb);
            return SchemeAndroid.lightFromCorePalette(core);
        };
        /**
         * @param argb ARGB representation of a color.
         * @return Dark Android color scheme, based on the color's hue.
         */
        SchemeAndroid.darkContent = function (argb) {
            var core = CorePalette.contentOf(argb);
            return SchemeAndroid.darkFromCorePalette(core);
        };
        /**
         * Light scheme from core palette
         */
        SchemeAndroid.lightFromCorePalette = function (core) {
            return new SchemeAndroid({
                colorAccentPrimary: core.a1.tone(90),
                colorAccentPrimaryVariant: core.a1.tone(40),
                colorAccentSecondary: core.a2.tone(90),
                colorAccentSecondaryVariant: core.a2.tone(40),
                colorAccentTertiary: core.a3.tone(90),
                colorAccentTertiaryVariant: core.a3.tone(40),
                textColorPrimary: core.n1.tone(10),
                textColorSecondary: core.n2.tone(30),
                textColorTertiary: core.n2.tone(50),
                textColorPrimaryInverse: core.n1.tone(95),
                textColorSecondaryInverse: core.n1.tone(80),
                textColorTertiaryInverse: core.n1.tone(60),
                colorBackground: core.n1.tone(95),
                colorBackgroundFloating: core.n1.tone(98),
                colorSurface: core.n1.tone(98),
                colorSurfaceVariant: core.n1.tone(90),
                colorSurfaceHighlight: core.n1.tone(100),
                surfaceHeader: core.n1.tone(90),
                underSurface: core.n1.tone(0),
                offState: core.n1.tone(20),
                accentSurface: core.a2.tone(95),
                textPrimaryOnAccent: core.n1.tone(10),
                textSecondaryOnAccent: core.n2.tone(30),
                volumeBackground: core.n1.tone(25),
                scrim: core.n1.tone(80),
            });
        };
        /**
         * Dark scheme from core palette
         */
        SchemeAndroid.darkFromCorePalette = function (core) {
            return new SchemeAndroid({
                colorAccentPrimary: core.a1.tone(90),
                colorAccentPrimaryVariant: core.a1.tone(70),
                colorAccentSecondary: core.a2.tone(90),
                colorAccentSecondaryVariant: core.a2.tone(70),
                colorAccentTertiary: core.a3.tone(90),
                colorAccentTertiaryVariant: core.a3.tone(70),
                textColorPrimary: core.n1.tone(95),
                textColorSecondary: core.n2.tone(80),
                textColorTertiary: core.n2.tone(60),
                textColorPrimaryInverse: core.n1.tone(10),
                textColorSecondaryInverse: core.n1.tone(30),
                textColorTertiaryInverse: core.n1.tone(50),
                colorBackground: core.n1.tone(10),
                colorBackgroundFloating: core.n1.tone(10),
                colorSurface: core.n1.tone(20),
                colorSurfaceVariant: core.n1.tone(30),
                colorSurfaceHighlight: core.n1.tone(35),
                surfaceHeader: core.n1.tone(30),
                underSurface: core.n1.tone(0),
                offState: core.n1.tone(20),
                accentSurface: core.a2.tone(95),
                textPrimaryOnAccent: core.n1.tone(10),
                textSecondaryOnAccent: core.n2.tone(30),
                volumeBackground: core.n1.tone(25),
                scrim: core.n1.tone(80),
            });
        };
        SchemeAndroid.prototype.toJSON = function () {
            return __assign({}, this.props);
        };
        return SchemeAndroid;
    }());

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A scheme that places the source color in `Scheme.primaryContainer`.
     *
     * Primary Container is the source color, adjusted for color relativity.
     * It maintains constant appearance in light mode and dark mode.
     * This adds ~5 tone in light mode, and subtracts ~5 tone in dark mode.
     * Tertiary Container is the complement to the source color, using
     * `TemperatureCache`. It also maintains constant appearance.
     */
    var SchemeContent = /** @class */ (function (_super) {
        __extends(SchemeContent, _super);
        function SchemeContent(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.CONTENT,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeContent;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A Dynamic Color theme that is intentionally detached from the source color.
     */
    var SchemeExpressive = /** @class */ (function (_super) {
        __extends(SchemeExpressive, _super);
        function SchemeExpressive(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.EXPRESSIVE,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeExpressive;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2023 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A scheme that places the source color in `Scheme.primaryContainer`.
     *
     * Primary Container is the source color, adjusted for color relativity.
     * It maintains constant appearance in light mode and dark mode.
     * This adds ~5 tone in light mode, and subtracts ~5 tone in dark mode.
     * Tertiary Container is the complement to the source color, using
     * `TemperatureCache`. It also maintains constant appearance.
     */
    var SchemeFidelity = /** @class */ (function (_super) {
        __extends(SchemeFidelity, _super);
        function SchemeFidelity(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.FIDELITY,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeFidelity;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A playful theme - the source color's hue does not appear in the theme.
     */
    var SchemeFruitSalad = /** @class */ (function (_super) {
        __extends(SchemeFruitSalad, _super);
        function SchemeFruitSalad(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.FRUIT_SALAD,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeFruitSalad;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /** A Dynamic Color theme that is grayscale. */
    var SchemeMonochrome = /** @class */ (function (_super) {
        __extends(SchemeMonochrome, _super);
        function SchemeMonochrome(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.MONOCHROME,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeMonochrome;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /** A Dynamic Color theme that is near grayscale. */
    var SchemeNeutral = /** @class */ (function (_super) {
        __extends(SchemeNeutral, _super);
        function SchemeNeutral(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.NEUTRAL,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeNeutral;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A playful theme - the source color's hue does not appear in the theme.
     */
    var SchemeRainbow = /** @class */ (function (_super) {
        __extends(SchemeRainbow, _super);
        function SchemeRainbow(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.RAINBOW,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeRainbow;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A Dynamic Color theme with low to medium colorfulness and a Tertiary
     * TonalPalette with a hue related to the source color.
     *
     * The default Material You theme on Android 12 and 13.
     */
    var SchemeTonalSpot = /** @class */ (function (_super) {
        __extends(SchemeTonalSpot, _super);
        function SchemeTonalSpot(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.TONAL_SPOT,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeTonalSpot;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2022 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * A Dynamic Color theme that maxes out colorfulness at each position in the
     * Primary Tonal Palette.
     */
    var SchemeVibrant = /** @class */ (function (_super) {
        __extends(SchemeVibrant, _super);
        function SchemeVibrant(sourceColorHct, isDark, contrastLevel, specVersion, platform) {
            if (specVersion === void 0) { specVersion = DynamicScheme.DEFAULT_SPEC_VERSION; }
            if (platform === void 0) { platform = DynamicScheme.DEFAULT_PLATFORM; }
            return _super.call(this, {
                sourceColorHct: sourceColorHct,
                variant: exports.Variant.VIBRANT,
                contrastLevel: contrastLevel,
                isDark: isDark,
                platform: platform,
                specVersion: specVersion,
            }) || this;
        }
        return SchemeVibrant;
    }(DynamicScheme));

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Utility methods for hexadecimal representations of colors.
     */
    /**
     * @param argb ARGB representation of a color.
     * @return Hex string representing color, ex. #ff0000 for red.
     */
    function hexFromArgb(argb) {
        var e_1, _a;
        var r = redFromArgb(argb);
        var g = greenFromArgb(argb);
        var b = blueFromArgb(argb);
        var outParts = [r.toString(16), g.toString(16), b.toString(16)];
        try {
            // Pad single-digit output values
            for (var _b = __values(outParts.entries()), _c = _b.next(); !_c.done; _c = _b.next()) {
                var _d = __read(_c.value, 2), i = _d[0], part = _d[1];
                if (part.length === 1) {
                    outParts[i] = '0' + part;
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_1) throw e_1.error; }
        }
        return '#' + outParts.join('');
    }
    /**
     * @param hex String representing color as hex code. Accepts strings with or
     *     without leading #, and string representing the color using 3, 6, or 8
     *     hex characters.
     * @return ARGB representation of color.
     */
    function argbFromHex(hex) {
        hex = hex.replace('#', '');
        var isThree = hex.length === 3;
        var isSix = hex.length === 6;
        var isEight = hex.length === 8;
        if (!isThree && !isSix && !isEight) {
            throw new Error('unexpected hex ' + hex);
        }
        var r = 0;
        var g = 0;
        var b = 0;
        if (isThree) {
            r = parseIntHex(hex.slice(0, 1).repeat(2));
            g = parseIntHex(hex.slice(1, 2).repeat(2));
            b = parseIntHex(hex.slice(2, 3).repeat(2));
        }
        else if (isSix) {
            r = parseIntHex(hex.slice(0, 2));
            g = parseIntHex(hex.slice(2, 4));
            b = parseIntHex(hex.slice(4, 6));
        }
        else if (isEight) {
            r = parseIntHex(hex.slice(2, 4));
            g = parseIntHex(hex.slice(4, 6));
            b = parseIntHex(hex.slice(6, 8));
        }
        return (((255 << 24) | ((r & 0x0ff) << 16) | ((g & 0x0ff) << 8) | (b & 0x0ff)) >>>
            0);
    }
    function parseIntHex(value) {
        // tslint:disable-next-line:ban
        return parseInt(value, 16);
    }

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Provides conversions needed for K-Means quantization. Converting input to
     * points, and converting the final state of the K-Means algorithm to colors.
     */
    var LabPointProvider = /** @class */ (function () {
        function LabPointProvider() {
        }
        /**
         * Convert a color represented in ARGB to a 3-element array of L*a*b*
         * coordinates of the color.
         */
        LabPointProvider.prototype.fromInt = function (argb) {
            return labFromArgb(argb);
        };
        /**
         * Convert a 3-element array to a color represented in ARGB.
         */
        LabPointProvider.prototype.toInt = function (point) {
            return argbFromLab(point[0], point[1], point[2]);
        };
        /**
         * Standard CIE 1976 delta E formula also takes the square root, unneeded
         * here. This method is used by quantization algorithms to compare distance,
         * and the relative ordering is the same, with or without a square root.
         *
         * This relatively minor optimization is helpful because this method is
         * called at least once for each pixel in an image.
         */
        LabPointProvider.prototype.distance = function (from, to) {
            var dL = from[0] - to[0];
            var dA = from[1] - to[1];
            var dB = from[2] - to[2];
            return dL * dL + dA * dA + dB * dB;
        };
        return LabPointProvider;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    var MAX_ITERATIONS = 10;
    var MIN_MOVEMENT_DISTANCE = 3.0;
    /**
     * An image quantizer that improves on the speed of a standard K-Means algorithm
     * by implementing several optimizations, including deduping identical pixels
     * and a triangle inequality rule that reduces the number of comparisons needed
     * to identify which cluster a point should be moved to.
     *
     * Wsmeans stands for Weighted Square Means.
     *
     * This algorithm was designed by M. Emre Celebi, and was found in their 2011
     * paper, Improving the Performance of K-Means for Color Quantization.
     * https://arxiv.org/abs/1101.0395
     */
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable-next-line:class-as-namespace
    var QuantizerWsmeans = /** @class */ (function () {
        function QuantizerWsmeans() {
        }
        /**
         * @param inputPixels Colors in ARGB format.
         * @param startingClusters Defines the initial state of the quantizer. Passing
         *     an empty array is fine, the implementation will create its own initial
         *     state that leads to reproducible results for the same inputs.
         *     Passing an array that is the result of Wu quantization leads to higher
         *     quality results.
         * @param maxColors The number of colors to divide the image into. A lower
         *     number of colors may be returned.
         * @return Colors in ARGB format.
         */
        QuantizerWsmeans.quantize = function (inputPixels, startingClusters, maxColors) {
            var pixelToCount = new Map();
            var points = new Array();
            var pixels = new Array();
            var pointProvider = new LabPointProvider();
            var pointCount = 0;
            for (var i = 0; i < inputPixels.length; i++) {
                var inputPixel = inputPixels[i];
                var pixelCount = pixelToCount.get(inputPixel);
                if (pixelCount === undefined) {
                    pointCount++;
                    points.push(pointProvider.fromInt(inputPixel));
                    pixels.push(inputPixel);
                    pixelToCount.set(inputPixel, 1);
                }
                else {
                    pixelToCount.set(inputPixel, pixelCount + 1);
                }
            }
            var counts = new Array();
            for (var i = 0; i < pointCount; i++) {
                var pixel = pixels[i];
                var count = pixelToCount.get(pixel);
                if (count !== undefined) {
                    counts[i] = count;
                }
            }
            var clusterCount = Math.min(maxColors, pointCount);
            if (startingClusters.length > 0) {
                clusterCount = Math.min(clusterCount, startingClusters.length);
            }
            var clusters = new Array();
            for (var i = 0; i < startingClusters.length; i++) {
                clusters.push(pointProvider.fromInt(startingClusters[i]));
            }
            var additionalClustersNeeded = clusterCount - clusters.length;
            if (startingClusters.length === 0 && additionalClustersNeeded > 0) {
                for (var i = 0; i < additionalClustersNeeded; i++) {
                    var l = Math.random() * 100.0;
                    var a = Math.random() * (100.0 - (-100) + 1) + -100;
                    var b = Math.random() * (100.0 - (-100) + 1) + -100;
                    clusters.push(new Array(l, a, b));
                }
            }
            var clusterIndices = new Array();
            for (var i = 0; i < pointCount; i++) {
                clusterIndices.push(Math.floor(Math.random() * clusterCount));
            }
            var indexMatrix = new Array();
            for (var i = 0; i < clusterCount; i++) {
                indexMatrix.push(new Array());
                for (var j = 0; j < clusterCount; j++) {
                    indexMatrix[i].push(0);
                }
            }
            var distanceToIndexMatrix = new Array();
            for (var i = 0; i < clusterCount; i++) {
                distanceToIndexMatrix.push(new Array());
                for (var j = 0; j < clusterCount; j++) {
                    distanceToIndexMatrix[i].push(new DistanceAndIndex());
                }
            }
            var pixelCountSums = new Array();
            for (var i = 0; i < clusterCount; i++) {
                pixelCountSums.push(0);
            }
            for (var iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
                for (var i = 0; i < clusterCount; i++) {
                    for (var j = i + 1; j < clusterCount; j++) {
                        var distance = pointProvider.distance(clusters[i], clusters[j]);
                        distanceToIndexMatrix[j][i].distance = distance;
                        distanceToIndexMatrix[j][i].index = i;
                        distanceToIndexMatrix[i][j].distance = distance;
                        distanceToIndexMatrix[i][j].index = j;
                    }
                    distanceToIndexMatrix[i].sort();
                    for (var j = 0; j < clusterCount; j++) {
                        indexMatrix[i][j] = distanceToIndexMatrix[i][j].index;
                    }
                }
                var pointsMoved = 0;
                for (var i = 0; i < pointCount; i++) {
                    var point = points[i];
                    var previousClusterIndex = clusterIndices[i];
                    var previousCluster = clusters[previousClusterIndex];
                    var previousDistance = pointProvider.distance(point, previousCluster);
                    var minimumDistance = previousDistance;
                    var newClusterIndex = -1;
                    for (var j = 0; j < clusterCount; j++) {
                        if (distanceToIndexMatrix[previousClusterIndex][j].distance >=
                            4 * previousDistance) {
                            continue;
                        }
                        var distance = pointProvider.distance(point, clusters[j]);
                        if (distance < minimumDistance) {
                            minimumDistance = distance;
                            newClusterIndex = j;
                        }
                    }
                    if (newClusterIndex !== -1) {
                        var distanceChange = Math.abs((Math.sqrt(minimumDistance) - Math.sqrt(previousDistance)));
                        if (distanceChange > MIN_MOVEMENT_DISTANCE) {
                            pointsMoved++;
                            clusterIndices[i] = newClusterIndex;
                        }
                    }
                }
                if (pointsMoved === 0 && iteration !== 0) {
                    break;
                }
                var componentASums = new Array(clusterCount).fill(0);
                var componentBSums = new Array(clusterCount).fill(0);
                var componentCSums = new Array(clusterCount).fill(0);
                for (var i = 0; i < clusterCount; i++) {
                    pixelCountSums[i] = 0;
                }
                for (var i = 0; i < pointCount; i++) {
                    var clusterIndex = clusterIndices[i];
                    var point = points[i];
                    var count = counts[i];
                    pixelCountSums[clusterIndex] += count;
                    componentASums[clusterIndex] += (point[0] * count);
                    componentBSums[clusterIndex] += (point[1] * count);
                    componentCSums[clusterIndex] += (point[2] * count);
                }
                for (var i = 0; i < clusterCount; i++) {
                    var count = pixelCountSums[i];
                    if (count === 0) {
                        clusters[i] = [0.0, 0.0, 0.0];
                        continue;
                    }
                    var a = componentASums[i] / count;
                    var b = componentBSums[i] / count;
                    var c = componentCSums[i] / count;
                    clusters[i] = [a, b, c];
                }
            }
            var argbToPopulation = new Map();
            for (var i = 0; i < clusterCount; i++) {
                var count = pixelCountSums[i];
                if (count === 0) {
                    continue;
                }
                var possibleNewCluster = pointProvider.toInt(clusters[i]);
                if (argbToPopulation.has(possibleNewCluster)) {
                    continue;
                }
                argbToPopulation.set(possibleNewCluster, count);
            }
            return argbToPopulation;
        };
        return QuantizerWsmeans;
    }());
    /**
     *  A wrapper for maintaining a table of distances between K-Means clusters.
     */
    var DistanceAndIndex = /** @class */ (function () {
        function DistanceAndIndex() {
            this.distance = -1;
            this.index = -1;
        }
        return DistanceAndIndex;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Quantizes an image into a map, with keys of ARGB colors, and values of the
     * number of times that color appears in the image.
     */
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable-next-line:class-as-namespace
    var QuantizerMap = /** @class */ (function () {
        function QuantizerMap() {
        }
        /**
         * @param pixels Colors in ARGB format.
         * @return A Map with keys of ARGB colors, and values of the number of times
         *     the color appears in the image.
         */
        QuantizerMap.quantize = function (pixels) {
            var _a;
            var countByColor = new Map();
            for (var i = 0; i < pixels.length; i++) {
                var pixel = pixels[i];
                var alpha = alphaFromArgb(pixel);
                if (alpha < 255) {
                    continue;
                }
                countByColor.set(pixel, ((_a = countByColor.get(pixel)) !== null && _a !== void 0 ? _a : 0) + 1);
            }
            return countByColor;
        };
        return QuantizerMap;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    var INDEX_BITS = 5;
    var SIDE_LENGTH = 33; // ((1 << INDEX_INDEX_BITS) + 1)
    var TOTAL_SIZE = 35937; // SIDE_LENGTH * SIDE_LENGTH * SIDE_LENGTH
    var directions = {
        RED: 'red',
        GREEN: 'green',
        BLUE: 'blue',
    };
    /**
     * An image quantizer that divides the image's pixels into clusters by
     * recursively cutting an RGB cube, based on the weight of pixels in each area
     * of the cube.
     *
     * The algorithm was described by Xiaolin Wu in Graphic Gems II, published in
     * 1991.
     */
    var QuantizerWu = /** @class */ (function () {
        function QuantizerWu(weights, momentsR, momentsG, momentsB, moments, cubes) {
            if (weights === void 0) { weights = []; }
            if (momentsR === void 0) { momentsR = []; }
            if (momentsG === void 0) { momentsG = []; }
            if (momentsB === void 0) { momentsB = []; }
            if (moments === void 0) { moments = []; }
            if (cubes === void 0) { cubes = []; }
            this.weights = weights;
            this.momentsR = momentsR;
            this.momentsG = momentsG;
            this.momentsB = momentsB;
            this.moments = moments;
            this.cubes = cubes;
        }
        /**
         * @param pixels Colors in ARGB format.
         * @param maxColors The number of colors to divide the image into. A lower
         *     number of colors may be returned.
         * @return Colors in ARGB format.
         */
        QuantizerWu.prototype.quantize = function (pixels, maxColors) {
            this.constructHistogram(pixels);
            this.computeMoments();
            var createBoxesResult = this.createBoxes(maxColors);
            var results = this.createResult(createBoxesResult.resultCount);
            return results;
        };
        QuantizerWu.prototype.constructHistogram = function (pixels) {
            var e_1, _a;
            var _b;
            this.weights = Array.from({ length: TOTAL_SIZE }).fill(0);
            this.momentsR = Array.from({ length: TOTAL_SIZE }).fill(0);
            this.momentsG = Array.from({ length: TOTAL_SIZE }).fill(0);
            this.momentsB = Array.from({ length: TOTAL_SIZE }).fill(0);
            this.moments = Array.from({ length: TOTAL_SIZE }).fill(0);
            var countByColor = QuantizerMap.quantize(pixels);
            try {
                for (var _c = __values(countByColor.entries()), _d = _c.next(); !_d.done; _d = _c.next()) {
                    var _e = __read(_d.value, 2), pixel = _e[0], count = _e[1];
                    var red = redFromArgb(pixel);
                    var green = greenFromArgb(pixel);
                    var blue = blueFromArgb(pixel);
                    var bitsToRemove = 8 - INDEX_BITS;
                    var iR = (red >> bitsToRemove) + 1;
                    var iG = (green >> bitsToRemove) + 1;
                    var iB = (blue >> bitsToRemove) + 1;
                    var index = this.getIndex(iR, iG, iB);
                    this.weights[index] = ((_b = this.weights[index]) !== null && _b !== void 0 ? _b : 0) + count;
                    this.momentsR[index] += count * red;
                    this.momentsG[index] += count * green;
                    this.momentsB[index] += count * blue;
                    this.moments[index] += count * (red * red + green * green + blue * blue);
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
                }
                finally { if (e_1) throw e_1.error; }
            }
        };
        QuantizerWu.prototype.computeMoments = function () {
            for (var r = 1; r < SIDE_LENGTH; r++) {
                var area = Array.from({ length: SIDE_LENGTH }).fill(0);
                var areaR = Array.from({ length: SIDE_LENGTH }).fill(0);
                var areaG = Array.from({ length: SIDE_LENGTH }).fill(0);
                var areaB = Array.from({ length: SIDE_LENGTH }).fill(0);
                var area2 = Array.from({ length: SIDE_LENGTH }).fill(0.0);
                for (var g = 1; g < SIDE_LENGTH; g++) {
                    var line = 0;
                    var lineR = 0;
                    var lineG = 0;
                    var lineB = 0;
                    var line2 = 0.0;
                    for (var b = 1; b < SIDE_LENGTH; b++) {
                        var index = this.getIndex(r, g, b);
                        line += this.weights[index];
                        lineR += this.momentsR[index];
                        lineG += this.momentsG[index];
                        lineB += this.momentsB[index];
                        line2 += this.moments[index];
                        area[b] += line;
                        areaR[b] += lineR;
                        areaG[b] += lineG;
                        areaB[b] += lineB;
                        area2[b] += line2;
                        var previousIndex = this.getIndex(r - 1, g, b);
                        this.weights[index] = this.weights[previousIndex] + area[b];
                        this.momentsR[index] = this.momentsR[previousIndex] + areaR[b];
                        this.momentsG[index] = this.momentsG[previousIndex] + areaG[b];
                        this.momentsB[index] = this.momentsB[previousIndex] + areaB[b];
                        this.moments[index] = this.moments[previousIndex] + area2[b];
                    }
                }
            }
        };
        QuantizerWu.prototype.createBoxes = function (maxColors) {
            this.cubes =
                Array.from({ length: maxColors }).fill(0).map(function () { return new Box(); });
            var volumeVariance = Array.from({ length: maxColors }).fill(0.0);
            this.cubes[0].r0 = 0;
            this.cubes[0].g0 = 0;
            this.cubes[0].b0 = 0;
            this.cubes[0].r1 = SIDE_LENGTH - 1;
            this.cubes[0].g1 = SIDE_LENGTH - 1;
            this.cubes[0].b1 = SIDE_LENGTH - 1;
            var generatedColorCount = maxColors;
            var next = 0;
            for (var i = 1; i < maxColors; i++) {
                if (this.cut(this.cubes[next], this.cubes[i])) {
                    volumeVariance[next] =
                        this.cubes[next].vol > 1 ? this.variance(this.cubes[next]) : 0.0;
                    volumeVariance[i] =
                        this.cubes[i].vol > 1 ? this.variance(this.cubes[i]) : 0.0;
                }
                else {
                    volumeVariance[next] = 0.0;
                    i--;
                }
                next = 0;
                var temp = volumeVariance[0];
                for (var j = 1; j <= i; j++) {
                    if (volumeVariance[j] > temp) {
                        temp = volumeVariance[j];
                        next = j;
                    }
                }
                if (temp <= 0.0) {
                    generatedColorCount = i + 1;
                    break;
                }
            }
            return new CreateBoxesResult(maxColors, generatedColorCount);
        };
        QuantizerWu.prototype.createResult = function (colorCount) {
            var colors = [];
            for (var i = 0; i < colorCount; ++i) {
                var cube = this.cubes[i];
                var weight = this.volume(cube, this.weights);
                if (weight > 0) {
                    var r = Math.round(this.volume(cube, this.momentsR) / weight);
                    var g = Math.round(this.volume(cube, this.momentsG) / weight);
                    var b = Math.round(this.volume(cube, this.momentsB) / weight);
                    var color = (255 << 24) | ((r & 0x0ff) << 16) | ((g & 0x0ff) << 8) |
                        (b & 0x0ff);
                    colors.push(color);
                }
            }
            return colors;
        };
        QuantizerWu.prototype.variance = function (cube) {
            var dr = this.volume(cube, this.momentsR);
            var dg = this.volume(cube, this.momentsG);
            var db = this.volume(cube, this.momentsB);
            var xx = this.moments[this.getIndex(cube.r1, cube.g1, cube.b1)] -
                this.moments[this.getIndex(cube.r1, cube.g1, cube.b0)] -
                this.moments[this.getIndex(cube.r1, cube.g0, cube.b1)] +
                this.moments[this.getIndex(cube.r1, cube.g0, cube.b0)] -
                this.moments[this.getIndex(cube.r0, cube.g1, cube.b1)] +
                this.moments[this.getIndex(cube.r0, cube.g1, cube.b0)] +
                this.moments[this.getIndex(cube.r0, cube.g0, cube.b1)] -
                this.moments[this.getIndex(cube.r0, cube.g0, cube.b0)];
            var hypotenuse = dr * dr + dg * dg + db * db;
            var volume = this.volume(cube, this.weights);
            return xx - hypotenuse / volume;
        };
        QuantizerWu.prototype.cut = function (one, two) {
            var wholeR = this.volume(one, this.momentsR);
            var wholeG = this.volume(one, this.momentsG);
            var wholeB = this.volume(one, this.momentsB);
            var wholeW = this.volume(one, this.weights);
            var maxRResult = this.maximize(one, directions.RED, one.r0 + 1, one.r1, wholeR, wholeG, wholeB, wholeW);
            var maxGResult = this.maximize(one, directions.GREEN, one.g0 + 1, one.g1, wholeR, wholeG, wholeB, wholeW);
            var maxBResult = this.maximize(one, directions.BLUE, one.b0 + 1, one.b1, wholeR, wholeG, wholeB, wholeW);
            var direction;
            var maxR = maxRResult.maximum;
            var maxG = maxGResult.maximum;
            var maxB = maxBResult.maximum;
            if (maxR >= maxG && maxR >= maxB) {
                if (maxRResult.cutLocation < 0) {
                    return false;
                }
                direction = directions.RED;
            }
            else if (maxG >= maxR && maxG >= maxB) {
                direction = directions.GREEN;
            }
            else {
                direction = directions.BLUE;
            }
            two.r1 = one.r1;
            two.g1 = one.g1;
            two.b1 = one.b1;
            switch (direction) {
                case directions.RED:
                    one.r1 = maxRResult.cutLocation;
                    two.r0 = one.r1;
                    two.g0 = one.g0;
                    two.b0 = one.b0;
                    break;
                case directions.GREEN:
                    one.g1 = maxGResult.cutLocation;
                    two.r0 = one.r0;
                    two.g0 = one.g1;
                    two.b0 = one.b0;
                    break;
                case directions.BLUE:
                    one.b1 = maxBResult.cutLocation;
                    two.r0 = one.r0;
                    two.g0 = one.g0;
                    two.b0 = one.b1;
                    break;
                default:
                    throw new Error('unexpected direction ' + direction);
            }
            one.vol = (one.r1 - one.r0) * (one.g1 - one.g0) * (one.b1 - one.b0);
            two.vol = (two.r1 - two.r0) * (two.g1 - two.g0) * (two.b1 - two.b0);
            return true;
        };
        QuantizerWu.prototype.maximize = function (cube, direction, first, last, wholeR, wholeG, wholeB, wholeW) {
            var bottomR = this.bottom(cube, direction, this.momentsR);
            var bottomG = this.bottom(cube, direction, this.momentsG);
            var bottomB = this.bottom(cube, direction, this.momentsB);
            var bottomW = this.bottom(cube, direction, this.weights);
            var max = 0.0;
            var cut = -1;
            var halfR = 0;
            var halfG = 0;
            var halfB = 0;
            var halfW = 0;
            for (var i = first; i < last; i++) {
                halfR = bottomR + this.top(cube, direction, i, this.momentsR);
                halfG = bottomG + this.top(cube, direction, i, this.momentsG);
                halfB = bottomB + this.top(cube, direction, i, this.momentsB);
                halfW = bottomW + this.top(cube, direction, i, this.weights);
                if (halfW === 0) {
                    continue;
                }
                var tempNumerator = (halfR * halfR + halfG * halfG + halfB * halfB) * 1.0;
                var tempDenominator = halfW * 1.0;
                var temp = tempNumerator / tempDenominator;
                halfR = wholeR - halfR;
                halfG = wholeG - halfG;
                halfB = wholeB - halfB;
                halfW = wholeW - halfW;
                if (halfW === 0) {
                    continue;
                }
                tempNumerator = (halfR * halfR + halfG * halfG + halfB * halfB) * 1.0;
                tempDenominator = halfW * 1.0;
                temp += tempNumerator / tempDenominator;
                if (temp > max) {
                    max = temp;
                    cut = i;
                }
            }
            return new MaximizeResult(cut, max);
        };
        QuantizerWu.prototype.volume = function (cube, moment) {
            return (moment[this.getIndex(cube.r1, cube.g1, cube.b1)] -
                moment[this.getIndex(cube.r1, cube.g1, cube.b0)] -
                moment[this.getIndex(cube.r1, cube.g0, cube.b1)] +
                moment[this.getIndex(cube.r1, cube.g0, cube.b0)] -
                moment[this.getIndex(cube.r0, cube.g1, cube.b1)] +
                moment[this.getIndex(cube.r0, cube.g1, cube.b0)] +
                moment[this.getIndex(cube.r0, cube.g0, cube.b1)] -
                moment[this.getIndex(cube.r0, cube.g0, cube.b0)]);
        };
        QuantizerWu.prototype.bottom = function (cube, direction, moment) {
            switch (direction) {
                case directions.RED:
                    return (-moment[this.getIndex(cube.r0, cube.g1, cube.b1)] +
                        moment[this.getIndex(cube.r0, cube.g1, cube.b0)] +
                        moment[this.getIndex(cube.r0, cube.g0, cube.b1)] -
                        moment[this.getIndex(cube.r0, cube.g0, cube.b0)]);
                case directions.GREEN:
                    return (-moment[this.getIndex(cube.r1, cube.g0, cube.b1)] +
                        moment[this.getIndex(cube.r1, cube.g0, cube.b0)] +
                        moment[this.getIndex(cube.r0, cube.g0, cube.b1)] -
                        moment[this.getIndex(cube.r0, cube.g0, cube.b0)]);
                case directions.BLUE:
                    return (-moment[this.getIndex(cube.r1, cube.g1, cube.b0)] +
                        moment[this.getIndex(cube.r1, cube.g0, cube.b0)] +
                        moment[this.getIndex(cube.r0, cube.g1, cube.b0)] -
                        moment[this.getIndex(cube.r0, cube.g0, cube.b0)]);
                default:
                    throw new Error('unexpected direction $direction');
            }
        };
        QuantizerWu.prototype.top = function (cube, direction, position, moment) {
            switch (direction) {
                case directions.RED:
                    return (moment[this.getIndex(position, cube.g1, cube.b1)] -
                        moment[this.getIndex(position, cube.g1, cube.b0)] -
                        moment[this.getIndex(position, cube.g0, cube.b1)] +
                        moment[this.getIndex(position, cube.g0, cube.b0)]);
                case directions.GREEN:
                    return (moment[this.getIndex(cube.r1, position, cube.b1)] -
                        moment[this.getIndex(cube.r1, position, cube.b0)] -
                        moment[this.getIndex(cube.r0, position, cube.b1)] +
                        moment[this.getIndex(cube.r0, position, cube.b0)]);
                case directions.BLUE:
                    return (moment[this.getIndex(cube.r1, cube.g1, position)] -
                        moment[this.getIndex(cube.r1, cube.g0, position)] -
                        moment[this.getIndex(cube.r0, cube.g1, position)] +
                        moment[this.getIndex(cube.r0, cube.g0, position)]);
                default:
                    throw new Error('unexpected direction $direction');
            }
        };
        QuantizerWu.prototype.getIndex = function (r, g, b) {
            return (r << (INDEX_BITS * 2)) + (r << (INDEX_BITS + 1)) + r +
                (g << INDEX_BITS) + g + b;
        };
        return QuantizerWu;
    }());
    /**
     * Keeps track of the state of each box created as the Wu  quantization
     * algorithm progresses through dividing the image's pixels as plotted in RGB.
     */
    var Box = /** @class */ (function () {
        function Box(r0, r1, g0, g1, b0, b1, vol) {
            if (r0 === void 0) { r0 = 0; }
            if (r1 === void 0) { r1 = 0; }
            if (g0 === void 0) { g0 = 0; }
            if (g1 === void 0) { g1 = 0; }
            if (b0 === void 0) { b0 = 0; }
            if (b1 === void 0) { b1 = 0; }
            if (vol === void 0) { vol = 0; }
            this.r0 = r0;
            this.r1 = r1;
            this.g0 = g0;
            this.g1 = g1;
            this.b0 = b0;
            this.b1 = b1;
            this.vol = vol;
        }
        return Box;
    }());
    /**
     * Represents final result of Wu algorithm.
     */
    var CreateBoxesResult = /** @class */ (function () {
        /**
         * @param requestedCount how many colors the caller asked to be returned from
         *     quantization.
         * @param resultCount the actual number of colors achieved from quantization.
         *     May be lower than the requested count.
         */
        function CreateBoxesResult(requestedCount, resultCount) {
            this.requestedCount = requestedCount;
            this.resultCount = resultCount;
        }
        return CreateBoxesResult;
    }());
    /**
     * Represents the result of calculating where to cut an existing box in such
     * a way to maximize variance between the two new boxes created by a cut.
     */
    var MaximizeResult = /** @class */ (function () {
        function MaximizeResult(cutLocation, maximum) {
            this.cutLocation = cutLocation;
            this.maximum = maximum;
        }
        return MaximizeResult;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * An image quantizer that improves on the quality of a standard K-Means
     * algorithm by setting the K-Means initial state to the output of a Wu
     * quantizer, instead of random centroids. Improves on speed by several
     * optimizations, as implemented in Wsmeans, or Weighted Square Means, K-Means
     * with those optimizations.
     *
     * This algorithm was designed by M. Emre Celebi, and was found in their 2011
     * paper, Improving the Performance of K-Means for Color Quantization.
     * https://arxiv.org/abs/1101.0395
     */
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable-next-line:class-as-namespace
    var QuantizerCelebi = /** @class */ (function () {
        function QuantizerCelebi() {
        }
        /**
         * @param pixels Colors in ARGB format.
         * @param maxColors The number of colors to divide the image into. A lower
         *     number of colors may be returned.
         * @return Map with keys of colors in ARGB format, and values of number of
         *     pixels in the original image that correspond to the color in the
         *     quantized image.
         */
        QuantizerCelebi.quantize = function (pixels, maxColors) {
            var wu = new QuantizerWu();
            var wuResult = wu.quantize(pixels, maxColors);
            return QuantizerWsmeans.quantize(pixels, wuResult, maxColors);
        };
        return QuantizerCelebi;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    var SCORE_OPTION_DEFAULTS = {
        desired: 4, // 4 colors matches what Android wallpaper picker.
        fallbackColorARGB: 0xff4285f4, // Google Blue.
        filter: true, // Avoid unsuitable colors.
    };
    function compare(a, b) {
        if (a.score > b.score) {
            return -1;
        }
        else if (a.score < b.score) {
            return 1;
        }
        return 0;
    }
    /**
     *  Given a large set of colors, remove colors that are unsuitable for a UI
     *  theme, and rank the rest based on suitability.
     *
     *  Enables use of a high cluster count for image quantization, thus ensuring
     *  colors aren't muddied, while curating the high cluster count to a much
     *  smaller number of appropriate choices.
     */
    var Score = /** @class */ (function () {
        function Score() {
        }
        /**
         * Given a map with keys of colors and values of how often the color appears,
         * rank the colors based on suitability for being used for a UI theme.
         *
         * @param colorsToPopulation map with keys of colors and values of how often
         *     the color appears, usually from a source image.
         * @param {ScoreOptions} options optional parameters.
         * @return Colors sorted by suitability for a UI theme. The most suitable
         *     color is the first item, the least suitable is the last. There will
         *     always be at least one color returned. If all the input colors
         *     were not suitable for a theme, a default fallback color will be
         *     provided, Google Blue.
         */
        Score.score = function (colorsToPopulation, options) {
            var e_1, _a, e_2, _b, e_3, _c;
            var _d = __assign(__assign({}, SCORE_OPTION_DEFAULTS), options), desired = _d.desired, fallbackColorARGB = _d.fallbackColorARGB, filter = _d.filter;
            // Get the HCT color for each Argb value, while finding the per hue count and
            // total count.
            var colorsHct = [];
            var huePopulation = new Array(360).fill(0);
            var populationSum = 0;
            try {
                for (var _e = __values(colorsToPopulation.entries()), _f = _e.next(); !_f.done; _f = _e.next()) {
                    var _g = __read(_f.value, 2), argb = _g[0], population = _g[1];
                    var hct = Hct.fromInt(argb);
                    colorsHct.push(hct);
                    var hue = Math.floor(hct.hue);
                    huePopulation[hue] += population;
                    populationSum += population;
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_f && !_f.done && (_a = _e.return)) _a.call(_e);
                }
                finally { if (e_1) throw e_1.error; }
            }
            // Hues with more usage in neighboring 30 degree slice get a larger number.
            var hueExcitedProportions = new Array(360).fill(0.0);
            for (var hue = 0; hue < 360; hue++) {
                var proportion = huePopulation[hue] / populationSum;
                for (var i = hue - 14; i < hue + 16; i++) {
                    var neighborHue = sanitizeDegreesInt(i);
                    hueExcitedProportions[neighborHue] += proportion;
                }
            }
            // Scores each HCT color based on usage and chroma, while optionally
            // filtering out values that do not have enough chroma or usage.
            var scoredHct = new Array();
            try {
                for (var colorsHct_1 = __values(colorsHct), colorsHct_1_1 = colorsHct_1.next(); !colorsHct_1_1.done; colorsHct_1_1 = colorsHct_1.next()) {
                    var hct = colorsHct_1_1.value;
                    var hue = sanitizeDegreesInt(Math.round(hct.hue));
                    var proportion = hueExcitedProportions[hue];
                    if (filter && (hct.chroma < Score.CUTOFF_CHROMA || proportion <= Score.CUTOFF_EXCITED_PROPORTION)) {
                        continue;
                    }
                    var proportionScore = proportion * 100.0 * Score.WEIGHT_PROPORTION;
                    var chromaWeight = hct.chroma < Score.TARGET_CHROMA ? Score.WEIGHT_CHROMA_BELOW : Score.WEIGHT_CHROMA_ABOVE;
                    var chromaScore = (hct.chroma - Score.TARGET_CHROMA) * chromaWeight;
                    var score = proportionScore + chromaScore;
                    scoredHct.push({ hct: hct, score: score });
                }
            }
            catch (e_2_1) { e_2 = { error: e_2_1 }; }
            finally {
                try {
                    if (colorsHct_1_1 && !colorsHct_1_1.done && (_b = colorsHct_1.return)) _b.call(colorsHct_1);
                }
                finally { if (e_2) throw e_2.error; }
            }
            // Sorted so that colors with higher scores come first.
            scoredHct.sort(compare);
            // Iterates through potential hue differences in degrees in order to select
            // the colors with the largest distribution of hues possible. Starting at
            // 90 degrees(maximum difference for 4 colors) then decreasing down to a
            // 15 degree minimum.
            var chosenColors = [];
            var _loop_1 = function (differenceDegrees$1) {
                var e_4, _h;
                chosenColors.length = 0;
                var _loop_2 = function (hct) {
                    var duplicateHue = chosenColors.find(function (chosenHct) {
                        return differenceDegrees(hct.hue, chosenHct.hue) < differenceDegrees$1;
                    });
                    if (!duplicateHue) {
                        chosenColors.push(hct);
                    }
                    if (chosenColors.length >= desired)
                        return "break";
                };
                try {
                    for (var scoredHct_1 = (e_4 = void 0, __values(scoredHct)), scoredHct_1_1 = scoredHct_1.next(); !scoredHct_1_1.done; scoredHct_1_1 = scoredHct_1.next()) {
                        var hct = scoredHct_1_1.value.hct;
                        var state_2 = _loop_2(hct);
                        if (state_2 === "break")
                            break;
                    }
                }
                catch (e_4_1) { e_4 = { error: e_4_1 }; }
                finally {
                    try {
                        if (scoredHct_1_1 && !scoredHct_1_1.done && (_h = scoredHct_1.return)) _h.call(scoredHct_1);
                    }
                    finally { if (e_4) throw e_4.error; }
                }
                if (chosenColors.length >= desired)
                    return "break";
            };
            for (var differenceDegrees$1 = 90; differenceDegrees$1 >= 15; differenceDegrees$1--) {
                var state_1 = _loop_1(differenceDegrees$1);
                if (state_1 === "break")
                    break;
            }
            var colors = [];
            if (chosenColors.length === 0) {
                colors.push(fallbackColorARGB);
            }
            try {
                for (var chosenColors_1 = __values(chosenColors), chosenColors_1_1 = chosenColors_1.next(); !chosenColors_1_1.done; chosenColors_1_1 = chosenColors_1.next()) {
                    var chosenHct = chosenColors_1_1.value;
                    colors.push(chosenHct.toInt());
                }
            }
            catch (e_3_1) { e_3 = { error: e_3_1 }; }
            finally {
                try {
                    if (chosenColors_1_1 && !chosenColors_1_1.done && (_c = chosenColors_1.return)) _c.call(chosenColors_1);
                }
                finally { if (e_3) throw e_3.error; }
            }
            return colors;
        };
        Score.TARGET_CHROMA = 48.0; // A1 Chroma
        Score.WEIGHT_PROPORTION = 0.7;
        Score.WEIGHT_CHROMA_ABOVE = 0.3;
        Score.WEIGHT_CHROMA_BELOW = 0.1;
        Score.CUTOFF_CHROMA = 5.0;
        Score.CUTOFF_EXCITED_PROPORTION = 0.01;
        return Score;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Get the source color from an image.
     *
     * @param image The image element
     * @return Source color - the color most suitable for creating a UI theme
     */
    function sourceColorFromImage(image) {
        return __awaiter(this, void 0, void 0, function () {
            var imageBytes;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, new Promise(function (resolve, reject) {
                            var canvas = document.createElement('canvas');
                            var context = canvas.getContext('2d');
                            if (!context) {
                                reject(new Error('Could not get canvas context'));
                                return;
                            }
                            var loadCallback = function () {
                                canvas.width = image.width;
                                canvas.height = image.height;
                                context.drawImage(image, 0, 0);
                                var rect = [0, 0, image.width, image.height];
                                var area = image.dataset['area'];
                                if (area && /^\d+(\s*,\s*\d+){3}$/.test(area)) {
                                    rect = area.split(/\s*,\s*/).map(function (s) {
                                        // tslint:disable-next-line:ban
                                        return parseInt(s, 10);
                                    });
                                }
                                var _a = __read(rect, 4), sx = _a[0], sy = _a[1], sw = _a[2], sh = _a[3];
                                resolve(context.getImageData(sx, sy, sw, sh).data);
                            };
                            var errorCallback = function () {
                                reject(new Error('Image load failed'));
                            };
                            if (image.complete) {
                                loadCallback();
                            }
                            else {
                                image.onload = loadCallback;
                                image.onerror = errorCallback;
                            }
                        })];
                    case 1:
                        imageBytes = _a.sent();
                        return [2 /*return*/, sourceColorFromImageBytes(imageBytes)];
                }
            });
        });
    }
    /**
     * Get the source color from image bytes.
     *
     * @param imageBytes The image bytes
     * @return Source color - the color most suitable for creating a UI theme
     */
    function sourceColorFromImageBytes(imageBytes) {
        // Convert Image data to Pixel Array
        var pixels = [];
        for (var i = 0; i < imageBytes.length; i += 4) {
            var r = imageBytes[i];
            var g = imageBytes[i + 1];
            var b = imageBytes[i + 2];
            var a = imageBytes[i + 3];
            if (a < 255) {
                continue;
            }
            var argb = argbFromRgb(r, g, b);
            pixels.push(argb);
        }
        // Convert Pixels to Material Colors
        var result = QuantizerCelebi.quantize(pixels, 128);
        var ranked = Score.score(result);
        var top = ranked[0];
        return top;
    }

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    // This file is automatically generated. Do not modify it.
    // material_color_utilities is designed to have a consistent API across
    // platforms and modular components that can be moved around easily. Using a
    // class as a namespace facilitates this.
    //
    // tslint:disable:class-as-namespace
    /**
     * Functions for blending in HCT and CAM16.
     */
    var Blend = /** @class */ (function () {
        function Blend() {
        }
        /**
         * Blend the design color's HCT hue towards the key color's HCT
         * hue, in a way that leaves the original color recognizable and
         * recognizably shifted towards the key color.
         *
         * @param designColor ARGB representation of an arbitrary color.
         * @param sourceColor ARGB representation of the main theme color.
         * @return The design color with a hue shifted towards the
         * system's color, a slightly warmer/cooler variant of the design
         * color's hue.
         */
        Blend.harmonize = function (designColor, sourceColor) {
            var fromHct = Hct.fromInt(designColor);
            var toHct = Hct.fromInt(sourceColor);
            var differenceDegrees$1 = differenceDegrees(fromHct.hue, toHct.hue);
            var rotationDegrees = Math.min(differenceDegrees$1 * 0.5, 15.0);
            var outputHue = sanitizeDegreesDouble(fromHct.hue +
                rotationDegrees * rotationDirection(fromHct.hue, toHct.hue));
            return Hct.from(outputHue, fromHct.chroma, fromHct.tone).toInt();
        };
        /**
         * Blends hue from one color into another. The chroma and tone of
         * the original color are maintained.
         *
         * @param from ARGB representation of color
         * @param to ARGB representation of color
         * @param amount how much blending to perform; 0.0 >= and <= 1.0
         * @return from, with a hue blended towards to. Chroma and tone
         * are constant.
         */
        Blend.hctHue = function (from, to, amount) {
            var ucs = Blend.cam16Ucs(from, to, amount);
            var ucsCam = Cam16.fromInt(ucs);
            var fromCam = Cam16.fromInt(from);
            var blended = Hct.from(ucsCam.hue, fromCam.chroma, lstarFromArgb(from));
            return blended.toInt();
        };
        /**
         * Blend in CAM16-UCS space.
         *
         * @param from ARGB representation of color
         * @param to ARGB representation of color
         * @param amount how much blending to perform; 0.0 >= and <= 1.0
         * @return from, blended towards to. Hue, chroma, and tone will
         * change.
         */
        Blend.cam16Ucs = function (from, to, amount) {
            var fromCam = Cam16.fromInt(from);
            var toCam = Cam16.fromInt(to);
            var fromJ = fromCam.jstar;
            var fromA = fromCam.astar;
            var fromB = fromCam.bstar;
            var toJ = toCam.jstar;
            var toA = toCam.astar;
            var toB = toCam.bstar;
            var jstar = fromJ + (toJ - fromJ) * amount;
            var astar = fromA + (toA - fromA) * amount;
            var bstar = fromB + (toB - fromB) * amount;
            return Cam16.fromUcs(jstar, astar, bstar).toInt();
        };
        return Blend;
    }());

    /**
     * @license
     * Copyright 2021 Google LLC
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     *
     *      http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */
    /**
     * Generate a theme from a source color
     *
     * @param source Source color
     * @param customColors Array of custom colors
     * @return Theme object
     */
    function themeFromSourceColor(source, customColors) {
        if (customColors === void 0) { customColors = []; }
        var palette = CorePalette.of(source);
        return {
            source: source,
            schemes: {
                light: Scheme.light(source),
                dark: Scheme.dark(source),
            },
            palettes: {
                primary: palette.a1,
                secondary: palette.a2,
                tertiary: palette.a3,
                neutral: palette.n1,
                neutralVariant: palette.n2,
                error: palette.error,
            },
            customColors: customColors.map(function (c) { return customColor(source, c); }),
        };
    }
    /**
     * Generate a theme from an image source
     *
     * @param image Image element
     * @param customColors Array of custom colors
     * @return Theme object
     */
    function themeFromImage(image_1) {
        return __awaiter(this, arguments, void 0, function (image, customColors) {
            var source;
            if (customColors === void 0) { customColors = []; }
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, sourceColorFromImage(image)];
                    case 1:
                        source = _a.sent();
                        return [2 /*return*/, themeFromSourceColor(source, customColors)];
                }
            });
        });
    }
    /**
     * Generate custom color group from source and target color
     *
     * @param source Source color
     * @param color Custom color
     * @return Custom color group
     *
     * @link https://m3.material.io/styles/color/the-color-system/color-roles
     */
    function customColor(source, color) {
        var value = color.value;
        var from = value;
        var to = source;
        if (color.blend) {
            value = Blend.harmonize(from, to);
        }
        var palette = CorePalette.of(value);
        var tones = palette.a1;
        return {
            color: color,
            value: value,
            light: {
                color: tones.tone(40),
                onColor: tones.tone(100),
                colorContainer: tones.tone(90),
                onColorContainer: tones.tone(10),
            },
            dark: {
                color: tones.tone(80),
                onColor: tones.tone(20),
                colorContainer: tones.tone(30),
                onColorContainer: tones.tone(90),
            },
        };
    }
    /**
     * Apply a theme to an element
     *
     * @param theme Theme object
     * @param options Options
     */
    function applyTheme(theme, options) {
        var e_1, _a, e_2, _b;
        var _c, _d;
        var target = (options === null || options === void 0 ? void 0 : options.target) || document.body;
        var isDark = (_c = options === null || options === void 0 ? void 0 : options.dark) !== null && _c !== void 0 ? _c : false;
        var scheme = isDark ? theme.schemes.dark : theme.schemes.light;
        setSchemeProperties(target, scheme);
        if (options === null || options === void 0 ? void 0 : options.brightnessSuffix) {
            setSchemeProperties(target, theme.schemes.dark, '-dark');
            setSchemeProperties(target, theme.schemes.light, '-light');
        }
        if (options === null || options === void 0 ? void 0 : options.paletteTones) {
            var tones = (_d = options === null || options === void 0 ? void 0 : options.paletteTones) !== null && _d !== void 0 ? _d : [];
            try {
                for (var _e = __values(Object.entries(theme.palettes)), _f = _e.next(); !_f.done; _f = _e.next()) {
                    var _g = __read(_f.value, 2), key = _g[0], palette = _g[1];
                    var paletteKey = key.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
                    try {
                        for (var tones_1 = (e_2 = void 0, __values(tones)), tones_1_1 = tones_1.next(); !tones_1_1.done; tones_1_1 = tones_1.next()) {
                            var tone = tones_1_1.value;
                            var token = "--md-ref-palette-".concat(paletteKey, "-").concat(paletteKey).concat(tone);
                            var color = hexFromArgb(palette.tone(tone));
                            target.style.setProperty(token, color);
                        }
                    }
                    catch (e_2_1) { e_2 = { error: e_2_1 }; }
                    finally {
                        try {
                            if (tones_1_1 && !tones_1_1.done && (_b = tones_1.return)) _b.call(tones_1);
                        }
                        finally { if (e_2) throw e_2.error; }
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_f && !_f.done && (_a = _e.return)) _a.call(_e);
                }
                finally { if (e_1) throw e_1.error; }
            }
        }
    }
    function setSchemeProperties(target, scheme, suffix) {
        var e_3, _a;
        if (suffix === void 0) { suffix = ''; }
        try {
            for (var _b = __values(Object.entries(scheme.toJSON())), _c = _b.next(); !_c.done; _c = _b.next()) {
                var _d = __read(_c.value, 2), key = _d[0], value = _d[1];
                var token = key.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
                var color = hexFromArgb(value);
                target.style.setProperty("--md-sys-color-".concat(token).concat(suffix), color);
            }
        }
        catch (e_3_1) { e_3 = { error: e_3_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_3) throw e_3.error; }
        }
    }

    exports.Cam16 = Cam16;
    exports.CorePalette = CorePalette;
    exports.DynamicColor = DynamicColor;
    exports.DynamicScheme = DynamicScheme;
    exports.Hct = Hct;
    exports.MaterialDynamicColors = MaterialDynamicColors;
    exports.Scheme = Scheme;
    exports.SchemeAndroid = SchemeAndroid;
    exports.SchemeContent = SchemeContent;
    exports.SchemeExpressive = SchemeExpressive;
    exports.SchemeFidelity = SchemeFidelity;
    exports.SchemeFruitSalad = SchemeFruitSalad;
    exports.SchemeMonochrome = SchemeMonochrome;
    exports.SchemeNeutral = SchemeNeutral;
    exports.SchemeRainbow = SchemeRainbow;
    exports.SchemeTonalSpot = SchemeTonalSpot;
    exports.SchemeVibrant = SchemeVibrant;
    exports.TonalPalette = TonalPalette;
    exports.ViewingConditions = ViewingConditions;
    exports.alphaFromArgb = alphaFromArgb;
    exports.applyTheme = applyTheme;
    exports.argbFromHex = argbFromHex;
    exports.argbFromLab = argbFromLab;
    exports.argbFromLinrgb = argbFromLinrgb;
    exports.argbFromLstar = argbFromLstar;
    exports.argbFromRgb = argbFromRgb;
    exports.argbFromXyz = argbFromXyz;
    exports.blueFromArgb = blueFromArgb;
    exports.clampDouble = clampDouble;
    exports.clampInt = clampInt;
    exports.customColor = customColor;
    exports.delinearized = delinearized;
    exports.differenceDegrees = differenceDegrees;
    exports.extendSpecVersion = extendSpecVersion;
    exports.greenFromArgb = greenFromArgb;
    exports.hexFromArgb = hexFromArgb;
    exports.isOpaque = isOpaque;
    exports.labFromArgb = labFromArgb;
    exports.lerp = lerp;
    exports.linearized = linearized;
    exports.lstarFromArgb = lstarFromArgb;
    exports.lstarFromY = lstarFromY;
    exports.matrixMultiply = matrixMultiply;
    exports.redFromArgb = redFromArgb;
    exports.rotationDirection = rotationDirection;
    exports.sanitizeDegreesDouble = sanitizeDegreesDouble;
    exports.sanitizeDegreesInt = sanitizeDegreesInt;
    exports.signum = signum;
    exports.sourceColorFromImage = sourceColorFromImage;
    exports.sourceColorFromImageBytes = sourceColorFromImageBytes;
    exports.themeFromImage = themeFromImage;
    exports.themeFromSourceColor = themeFromSourceColor;
    exports.whitePointD65 = whitePointD65;
    exports.xyzFromArgb = xyzFromArgb;
    exports.yFromLstar = yFromLstar;

    return exports;

})({});
