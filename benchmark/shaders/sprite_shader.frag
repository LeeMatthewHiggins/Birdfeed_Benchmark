uniform vec2 uCanvasSize;
uniform vec2 uGridSize;
uniform float uInstanceSize;
uniform vec2 uImageSize;
uniform float uTextureWidth;
uniform float uTextureHeight;
uniform float uCellsPerRow;
uniform float uCellDataWidth;
uniform float uCellSize;
uniform sampler2D uTexture;
uniform sampler2D uPositionData;
uniform sampler2D uCellCounts;

out vec4 fragColor;

const int kMaxSpritesPerCell = 255;
const float kSignedByteOffset = 128.0;

void main() {
  vec2 pixelPos = gl_FragCoord.xy;
  fragColor = vec4(0.0);

  vec2 cellCoord = floor(pixelPos / uCellSize);
  float cellIndex = cellCoord.y * uGridSize.x + cellCoord.x;

  vec2 pixelInCell = mod(pixelPos, uCellSize);

  vec2 cellCountUV = (cellCoord + 0.5) / uGridSize;
  float cellSpriteCount = texture(uCellCounts, cellCountUV).r * 255.0;

  float cellRow = floor(cellIndex / uCellsPerRow);
  float cellCol = mod(cellIndex, uCellsPerRow);
  float cellU = cellCol * uCellDataWidth;
  float cellV = cellRow;

  for (int i = 0; i < kMaxSpritesPerCell; i++) {
    if (float(i) >= cellSpriteCount) break;

    float pixelU = cellU + float(i) * 2.0;
    float u1 = (pixelU + 0.5) / uTextureWidth;
    float u2 = (pixelU + 1.5) / uTextureWidth;
    float v = (cellV + 0.5) / uTextureHeight;

    vec4 aabbData = texture(uPositionData, vec2(u1, v));
    vec4 srcData = texture(uPositionData, vec2(u2, v));

    float minX = (aabbData.r * 255.0) - kSignedByteOffset;
    float minY = (aabbData.g * 255.0) - kSignedByteOffset;
    float maxX = (aabbData.b * 255.0) - kSignedByteOffset;
    float maxY = (aabbData.a * 255.0) - kSignedByteOffset;

    float srcU = srcData.r;
    float srcV = srcData.g;
    float srcW = srcData.b;
    float srcH = srcData.a;

    if (pixelInCell.x >= minX && pixelInCell.x < maxX + 1.0 &&
        pixelInCell.y >= minY && pixelInCell.y < maxY + 1.0) {

      float localX = pixelInCell.x - minX;
      float localY = pixelInCell.y - minY;

      float width = maxX - minX;
      float height = maxY - minY;

      vec2 spriteUV = vec2(localX / width, localY / height);

      vec2 texCoord = vec2(srcU, srcV) + spriteUV * vec2(srcW, srcH);

      vec4 texColor = texture(uTexture, texCoord);
      fragColor = mix(fragColor, texColor, texColor.a);
    }
  }
}
