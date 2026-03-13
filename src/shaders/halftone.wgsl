struct InstanceInput {
    @location(5) model_matrix_0: vec4<f32>,
    @location(6) model_matrix_1: vec4<f32>,
    @location(7) model_matrix_2: vec4<f32>,
    @location(8) model_matrix_3: vec4<f32>,

    @location(9) normal_matrix_0: vec3<f32>,
    @location(10) normal_matrix_1: vec3<f32>,
    @location(11) normal_matrix_2: vec3<f32>,
};

struct Light {
    position: vec3<f32>,
    color: vec3<f32>,
}
@group(2) @binding(0)
var<uniform> light: Light;

// vertex shader
struct Camera {
    view_pos: vec4<f32>,
    view_proj: mat4x4<f32>,
};
@group(1) @binding(0)
var<uniform> camera: Camera;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
    @location(2) normal: vec3<f32>,
    @location(3) tangent: vec3<f32>,
    @location(4) bitangent: vec3<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) tangent_position: vec3<f32>,
    @location(2) tangent_light_position: vec3<f32>,
    @location(3) tangent_view_position: vec3<f32>,
};

@vertex
fn vs_main(
    model: VertexInput,
    instance: InstanceInput,
) -> VertexOutput {
    let coordinate_system = mat3x3<f32>(
        vec3(1, 0, 0), // x-axis (right)
        vec3(0, 1, 0), // y-axis (up)
        vec3(0, 0, 1),  // z-axis (forward)
    );

    let model_matrix = mat4x4<f32>(
        instance.model_matrix_0,
        instance.model_matrix_1,
        instance.model_matrix_2,
        instance.model_matrix_3,
    );

    let normal_matrix = mat3x3<f32>(
        instance.normal_matrix_0,
        instance.normal_matrix_1,
        instance.normal_matrix_2,
    );

    let world_normal = normalize(normal_matrix * model.normal);
    let world_tangent = normalize(normal_matrix * model.tangent);
    let world_bitangent = normalize(normal_matrix * model.bitangent);
    let tangent_matrix = transpose(mat3x3<f32>(
        world_tangent,
        world_bitangent,
        world_normal,
    ));

    let world_position = model_matrix * vec4<f32>(model.position, 1.0);

    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = camera.view_proj * world_position;
    out.tangent_position = tangent_matrix * world_position.xyz;
    out.tangent_view_position = tangent_matrix * camera.view_pos.xyz;
    out.tangent_light_position = tangent_matrix * light.position;

    return out;
}

// fragment shader
@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;
@group(0) @binding(2)
var t_normal: texture_2d<f32>;
@group(0) @binding(3)
var s_normal: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let object_color: vec4<f32> = textureSample(t_diffuse, s_diffuse, in.tex_coords);
    let object_normal: vec4<f32> = textureSample(t_normal, s_normal, in.tex_coords);

    let ambient_strength = 0.1;
    let ambient_color = light.color * ambient_strength;

    let tangent_normal = object_normal.xyz * 2.0 - 1.0;
    let light_dir = normalize(in.tangent_light_position - in.tangent_position);
    let view_dir = normalize(in.tangent_view_position - in.tangent_position);
    let half_dir = normalize(view_dir + light_dir);

    let diffuse_strength = max(dot(tangent_normal, light_dir), 0.0);
    let diffuse_color = light.color * diffuse_strength;

    let specular_strength = pow(max(dot(tangent_normal, half_dir), 0.0), 32.0);
    let specular_color = specular_strength * light.color;

    // apply the pips!
    let diffuse = light.color * (1 - 
        get_specular_pips(
            1 - clamp(
                dot(half_dir, object_normal.xyz),
                0.0, 100000.0
            ),
            in.clip_position
    ));
    let specular = light.color * get_specular_pips(
        clamp(
                dot(half_dir, object_normal.xyz),
                0.0, 100000.0
            ),
            in.clip_position
        );

    let result = (diffuse + ambient_color) * object_color.xyz;

    return vec4<f32>(result, object_color.a);
}

const PIP_SEPARATION = 10;

fn get_specular_pips(spec_mult: f32, pos: vec4<f32>) -> vec3<f32> {
    // find the distance to the nearest pip
    // compare that distance to spec_mult
    let pip: vec2<f32> = vec2(
	    2 * (abs(pos.x % PIP_SEPARATION / PIP_SEPARATION) - 0.5),
	    2 * (abs(pos.y % PIP_SEPARATION / PIP_SEPARATION) - 0.5),
    );

	let pip_distance: f32 = 
        sqrt(pow(pip.x, 2) + pow(pip.y, 2)) / sqrt(2.0);

	let spec_magnitude: f32 = sqrt(
        pow(spec_mult, 2) + 
        pow(spec_mult, 2) + 
        pow(spec_mult, 2)
    ) / sqrt(3.0);

	if(pip_distance < spec_magnitude) {
		return vec3(1.0);
	}

    return vec3(spec_mult);
}