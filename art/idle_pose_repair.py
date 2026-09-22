"""Sample glTF node poses. Idle channels are not rewritten."""
import bisect
import math


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def length(a): return math.sqrt(dot(a, a))
def unit(a): return mul(a, 1.0 / max(length(a), 1e-12))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def lerp(a, b, t): return add(mul(a, 1-t), mul(b, t))
def inverse(q): return (-q[0], -q[1], -q[2], q[3])


def product(a, b):
    return (*add(add(mul(b[:3], a[3]), mul(a[:3], b[3])), cross(a[:3], b[:3])),
            a[3]*b[3]-dot(a[:3], b[:3]))


def rotate(q, v):
    u = cross(q[:3], v)
    return add(v, add(mul(u, 2*q[3]), mul(cross(q[:3], u), 2)))


def slerp(a, b, t):
    d = dot(a, b)
    if d < 0: b, d = mul(b, -1), -d
    if d > .9995: return unit(lerp(a, b, t))
    theta = math.acos(max(-1, min(1, d)))
    return add(mul(a, math.sin((1-t)*theta)/math.sin(theta)), mul(b, math.sin(t*theta)/math.sin(theta)))


def rest_poses(gltf):
    poses = []
    for node in gltf['nodes']:
        if 'matrix' in node:
            raise ValueError('Pose sampling expects TRS nodes; matrix input needs explicit conversion')
        poses.append({'translation': tuple(node.get('translation', (0, 0, 0))),
                      'rotation': tuple(node.get('rotation', (0, 0, 0, 1))),
                      'scale': tuple(node.get('scale', (1, 1, 1)))})
    return poses


def read_channels(gltf, blob, anim, read):
    result = []
    for ch in anim['channels']:
        s = anim['samplers'][ch['sampler']]
        interpolation = s.get('interpolation', 'LINEAR')
        if interpolation not in ('LINEAR', 'STEP'):
            raise ValueError('Pose sampling requires LINEAR or STEP input')
        result.append((ch['target']['node'], ch['target']['path'],
                       [x[0] for x in read(gltf, blob, s['input'])],
                       read(gltf, blob, s['output']), interpolation))
    return result


def sample(rest, channels, time):
    poses = [dict(p) for p in rest]
    for node, kind, times, values, interpolation in channels:
        if kind not in ('translation', 'rotation', 'scale'):
            raise ValueError('Pose sampling does not rewrite morph animations')
        a = max(0, min(bisect.bisect_right(times, time)-1, len(times)-1))
        b = min(a+1, len(times)-1)
        t = 0 if a == b or interpolation == 'STEP' else (time-times[a])/(times[b]-times[a])
        poses[node][kind] = slerp(values[a], values[b], t) if kind == 'rotation' else lerp(values[a], values[b], t)
    return poses


def world_poses(poses, parents):
    cache = {}
    def resolve(i):
        if i in cache: return cache[i]
        p = poses[i]
        if i not in parents:
            result = (p['translation'], p['rotation'], p['scale'])
        else:
            pp, pq, ps = resolve(parents[i])
            result = (add(pp, rotate(pq, tuple(x*y for x,y in zip(ps, p['translation'])))),
                      product(pq, p['rotation']), tuple(x*y for x,y in zip(ps, p['scale'])))
        cache[i] = result
        return result
    for i in range(len(poses)): resolve(i)
    return cache
