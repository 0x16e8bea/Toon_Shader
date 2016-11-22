// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Toon/Postorizer" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Shininess("Shininess", Float) = 0.5
		_Ambience("Ambience", Int) = 1
		_Steps("Steps", Int) = 2
		_Transform("Transform", Vector) = (0, 0, 0)
		}
	
		SubShader{

			Pass {
			Tags { "LightMode" = "ForwardAdd"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile ANTIALIASING_ON ANTIALIASING_OFF fwdadd

			struct vertexIn {
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct vertexOut {
				float4 position : SV_POSITION;
				float4 color : COLOR; 
				float4 tex : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
				float4 posLight : TEXCOORD3;
			};
			
			uniform float4x4 unity_WorldToLight;
			uniform sampler2D _LightTextureB0;
			uniform float4 _LightColor0;

			uniform float _Steps;
			uniform int _Ambience;
			uniform float3 _Transform;			
			uniform float4 _Color;
			uniform sampler2D _MainTex;


			vertexOut vert(vertexIn i) {
				vertexOut o;

				o.position = mul(UNITY_MATRIX_MVP, i.vertex);
				o.normalDir = normalize(mul(i.normal, unity_WorldToObject).xyz);
				o.posWorld = mul(unity_ObjectToWorld, i.vertex);
				o.color = _Color;
				o.posLight = mul(unity_WorldToLight, o.posWorld);
				o.tex = i.texcoord;

				return o;
			}

			// attenuation = tex2D(_LightTextureB0, float2(distance, distance)).a;


			float4 frag(vertexOut i) : COLOR {
				float3 lightDir;
				float atten;


				if (0.0 == _WorldSpaceLightPos0.w) {
					lightDir = normalize(_WorldSpaceLightPos0.xyz);
					atten = 1.0;
				}
				else {
					float3 vertexToLight = _WorldSpaceLightPos0.xyz - i.posWorld;
					lightDir = normalize(vertexToLight);
										
					float dist = length(vertexToLight);
					atten = 1 / length(vertexToLight);
				}

				half diffuse = max(0, dot(i.normalDir, lightDir)) * min(1.0, _LightColor0 * atten);

				half step = 1/ _Steps;
				half level = floor(diffuse / step);
				half E = fwidth(diffuse);

				float4 c = tex2D(_MainTex, i.tex.xy);

				#if defined(ANTIALIASING_ON)

				// Apply diffuse and antialias the transitions by checking if the current pixel (diffuse) is within an epsilon (E).
				if (level > step) {
					c = lerp(step * level * min(1.0, _LightColor0), step * (level + 1), smoothstep(step * level - E, step * level + E, diffuse)) * c * min(1.0, _LightColor0);
				}
				else {
					c = 1 * step * c * min(1.0, _LightColor0);
				}

				#endif

				#if defined(ANTIALIASING_OFF)

				c = floor(diffuse / step + 1) * step * c;

				#endif

				return c;
			}

			ENDCG

			}
		}
			FallBack "Diffuse"
}
