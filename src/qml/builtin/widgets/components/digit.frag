#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
} ubuf;

layout(binding = 1) uniform sampler2D sourceOld;
layout(binding = 2) uniform sampler2D sourceNew;

void main() {
    float p = ubuf.progress;
    vec2 uv = qt_TexCoord0;
    
    // 1. 计算遮罩边界（模仿你之前的 LinearGradient 逻辑）
    // 随着 p 增加，这个边界从 1.0 (底部) 移动到 0.0 (顶部)
    float edge = 1.0 - p; 
    float smoothness = 0.02; // 边缘羽化范围
    
    // 2. 采样旧数字和新数字
    vec4 colOld = texture(sourceOld, uv);
    vec4 colNew = texture(sourceNew, uv);
    
    // 3. 核心逻辑：
    // 当 uv.y < edge 时，显示旧数字的一部分
    // 当 uv.y > edge 时，显示新数字的一部分
    
    // 旧数字的遮罩：在 edge 之上的部分保留，之下消失
    float maskOld = 1.0 - smoothstep(edge - smoothness, edge, uv.y);
    // 新数字的遮罩：在 edge 之下的部分保留，之上消失
    float maskNew = smoothstep(edge - smoothness, edge, uv.y);
    
    // 4. 混合输出
    // 这样新旧数字在 edge 处完美衔接，不会出现奇怪的重叠
    vec4 finalCol = (colOld * maskOld * (1.0 - p)) + (colNew * maskNew * p);
    
    fragColor = finalCol * ubuf.qt_Opacity;
}

// qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 .\src\qml\builtin\widgets\components\digit.frag -o .\src\qml\builtin\widgets\components\digit.frag.qsb