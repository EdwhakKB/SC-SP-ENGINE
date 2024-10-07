 #pragma header // added space

  const float PI = 3.14159265; // was "#definePI 3.14159265"  which is nonsense
  uniform float xrot; // uniforms cant have default values, assign in the constructor
  uniform float yrot; // uniforms cant have default values, assign in the constructor
  uniform float zrot; // uniforms cant have default values, assign in the constructor
  uniform float depth; // uniforms cant have default values, assign in the constructor
  float plane( in vec3 norm, in vec3 po, in vec3 ro, in vec3 rd)
  {
    float
    de = dot(norm, rd);
    de = sign(de) * max(abs(de), 0.001);
    return dot(norm, po - ro) / de;
  }
  vec2 raytraceTexturedQuad( in vec3 rayOrigin, in vec3 rayDirection, in vec3 quadCenter, in vec3 quadRotation, in vec2 quadDimensions)
  {
    // Rotations ------------------
    float
    a = sin(quadRotation.x);
    float
    b = cos(quadRotation.x);
    float
    c = sin(quadRotation.y);
    float
    d = cos(quadRotation.y);
    float
    e = sin(quadRotation.z);
    float
    f = cos(quadRotation.z);
    float
    ac = a * c;
    float
    bc = b * c;
    mat3
    RotationMatrix = mat3(d * f, d * e, -c, ac * f - b * e, ac * e + b * f, a * d, bc * f + a * e, bc * e - a * f, b * d);
    //--------------------------------------
    vec3
    right = RotationMatrix * vec3(quadDimensions.x, 0.0, 0.0);
    vec3
    up = RotationMatrix * vec3(0.0, quadDimensions.y, 0.0); // prev version had 0, which is treated as an int
    vec3
    normal = cross(right, up);
    normal /= length(normal);
    // Find the plane hit point in space
    vec3
    pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;
    // Find the texture UV by projecting the hit point along the plane dirs
    return vec2(dot(pos, right) / dot(right, right), dot(pos, up) / dot(up, up)) + 0.5;
  }
  void main()
  {
    vec4
    texColor = texture2D(bitmap, openfl_TextureCoordv);
    // Screen UV goes from 0 - 1 along each axis
    vec2
    screenUV = openfl_TextureCoordv;
    vec2
    p = (2.0 * screenUV) - 1.0;
    float
    screenAspect = 1280.0 / 720.0; // added .0
    p.x *= screenAspect;
    // Normalized Ray Dir
    vec3
    dir = vec3(p.x, p.y, 1.0);
    dir /= length(dir);
    // Define the plane
    vec3
    planePosition = vec3(0.0, 0.0, depth + 0.5);
    vec3
    planeRotation = vec3(xrot, PI + yrot, zrot); // this the shit you needa change
    vec2
    planeDimension = vec2(-screenAspect, 1.0);
    vec2
    uv = raytraceTexturedQuad(vec3(0), dir, planePosition, planeRotation, planeDimension);
    // If we hit the rectangle, sample the texture
    if (abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5)
    {
      gl_FragColor = vec4(flixel_texture2D(bitmap, uv));
    }
  }
