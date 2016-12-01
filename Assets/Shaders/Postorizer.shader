// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Toon/Postorizer" {
	Properties{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ShadowTint("Shadow Tint", Color) = (0,0,0,0)
		_HighlightTint("Highlight Tint", Color) = (0,0,0,0)
		_Ambience("Ambience", Color) = (0,0,0,0)
		_Shininess("Shininess", Float) = 0
		_HighlightFactor("Highlight Factor", Float) = 10
		_HighlightSteps("Highlight Steps", Range(0, 10)) = 0
		_Steps("Diffuse_Steps", Range(1, 10)) = 2
		_Softness("Softness", Range(0, 0.1)) = 0
	}

		SubShader{
		Tags{ "RenderType" = "Opaque" }

			Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile ANTIALIASING_ON ANTIALIASING_OFF fwdadd
			#include "UnityCG.cginc"

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
			float4 vertex : TEXCOORD4;
		};

		uniform float4x4 unity_WorldToLight;
		uniform sampler2D _LightTextureB0;
		uniform float4 _LightColor0;

		uniform float _Steps;
		uniform float _HighlightSteps;
		uniform float _Shininess;
		uniform float _HighlightFactor;
		uniform float _Softness;
		uniform float4 _Ambience;
		uniform float4 _Color;
		uniform float4 _ShadowTint;
		uniform float4 _HighlightTint;
		uniform sampler2D _MainTex;

		vertexOut vert(vertexIn i) {
			vertexOut o;

			o.position = mul(UNITY_MATRIX_MVP, i.vertex);
			o.normalDir = normalize(mul(i.normal, unity_WorldToObject).xyz);
			o.posWorld = mul(unity_ObjectToWorld, i.vertex);
			o.color = _Color;
			o.posLight = mul(unity_WorldToLight, o.posWorld);
			o.tex = i.texcoord;
			o.vertex = i.vertex;

			return o;
		}


		float4 frag(vertexOut i) : COLOR {

			float3 lightDir;
			float atten;
			float3 vertexToLight;	

			// 4 Point Lights
			float3 n4LightDiffuse;
			float3 n4LightSpecular;

			float n4LightAtten;
			float4 n4LightColor;

			for (int index = 0; index < 4; index++) {

				// Get position of the 4 point lights (WORLD COORDINATES).
				float4 lightPosition = float4(unity_4LightPosX0[index],
					unity_4LightPosY0[index],
					unity_4LightPosZ0[index], 1.0);


				// Calculate prerequisites. 
				float3 vertexToLightSource =
					lightPosition.xyz - i.posWorld.xyz;
				float3 lightDirection = normalize(vertexToLightSource);
				float squaredDistance =
					dot(vertexToLightSource, vertexToLightSource);
				float attenuation = 1.0 / (1.0 +
					unity_4LightAtten0[index] * squaredDistance);

				float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld);

				// Linear model to maintain control over the amount of light steps.
				float3 diffuseReflection = attenuation * max(0.0, dot(i.normalDir, lightDirection));
				
				float3 specularReflection = mul(max(0.0, dot(reflect(-vertexToLightSource.xyz, i.normalDir.xyz), viewDir)), _Shininess) * attenuation;

				n4LightDiffuse = n4LightDiffuse + diffuseReflection * attenuation * unity_LightColor[index];
				n4LightSpecular = n4LightSpecular + specularReflection * attenuation * unity_LightColor[index] * _Shininess;

				n4LightAtten = n4LightAtten + attenuation * unity_LightColor[index];

				n4LightColor = n4LightColor + unity_LightColor[index];

			}

			// Set diffuse to maximum 0.99 (1.0 produce artifacts due to light step calculations) and add highlights.  
			half diffuse = min(0.99, float4(n4LightDiffuse, 1)) * max(1, min(_HighlightSteps / _Steps + 1, n4LightAtten * _HighlightFactor));
			half specular = n4LightSpecular;

			float4 c = tex2D(_MainTex, i.tex.xy) * _Color + _Ambience;

			half step = 1 / _Steps;
			half level = floor((diffuse + specular) / step);
			half E = fwidth(diffuse + specular);


			#if defined(ANTIALIASING_ON)

			// Apply diffuse and antialias the transitions by checking if the current pixel (diffuse) is within an epsilon (E).
			if (level > step) {
				c = lerp(step * level, step * (level + 1), smoothstep(step * level - E, step * level + E + _Softness, pow(diffuse + specular, 1.1))) * c + (min(1, _ShadowTint) * step * (level - _Steps)) + (min(1, _HighlightTint) * step * (level));
			}
			else {
				c = step * c * 1 + (min(1, _ShadowTint) * step * (level - _Steps)) + (min(1, _HighlightTint) * step * (level));
			}

			#endif

			#if defined(ANTIALIASING_OFF)

			c = floor(diffuse / step + 1) * step * c;

			#endif

			return c;
			}
			ENDCG
		}

			/*Pass {
			Tags { "LightMode" = "ForwardAdd"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile ANTIALIASING_ON ANTIALIASING_OFF fwdadd
			#include "UnityCG.cginc"

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
				float4 vertex : TEXCOORD4;
			};

			uniform float4x4 unity_WorldToLight;
			uniform sampler2D _LightTextureB0;
			uniform float4 _LightColor0;

			uniform float _Steps;
			uniform float _HighlightSteps;
			uniform float _Shininess;
			uniform float _AttenFactor;
			uniform float _Softness;
			uniform float4 _Ambience;
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
				o.vertex = i.vertex;

				return o;
			}


			float4 frag(vertexOut i) : COLOR {
				float3 lightDir;
				float atten;
				float3 vertexToLight;
				float3 viewDir;

				if (0.0 == _WorldSpaceLightPos0.w) {
					lightDir = normalize(_WorldSpaceLightPos0.xyz);
					atten = 1.0;
				}
				else {
					vertexToLight = _WorldSpaceLightPos0.xyz - i.posWorld;
					viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);

					lightDir = normalize(vertexToLight);

					float dist = length(vertexToLight);
					atten = 1 / dist;

				}

				half diffuse = max(0, dot(i.normalDir, lightDir)) * min(_HighlightSteps / _Steps + 1, atten * _AttenFactor);
				half specular = mul(max(0.0, dot(reflect(-vertexToLight.xyz, i.normalDir.xyz), viewDir)), _Shininess) * atten;

				float4 c = tex2D(_MainTex, i.tex.xy) * _LightColor0 * _Color + _Ambience;


				half step = 1 / _Steps;
				half level = floor((diffuse + specular) / step);
				half E = fwidth(diffuse + specular);


				#if defined(ANTIALIASING_ON)

				// Apply diffuse and antialias the transitions by checking if the current pixel (diffuse) is within an epsilon (E).
				if (level > step) {

					c = lerp(step * level, step * (level + 1), smoothstep(step * level - E, step * level + E + _Softness, pow(diffuse + specular, 1.1))) * c;
				}
				else {
					c = step * c * 1;
				}

				#endif

				#if defined(ANTIALIASING_OFF)

				c = floor(diffuse / step + 1) * step * c;

				#endif

				return c;
			}

			ENDCG

			}*/


		}

			FallBack "Diffuse"
}
