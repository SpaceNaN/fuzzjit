
function f() {
    let v3 = new Uint8ClampedArray(arguments);
    v3[0] = 4294967296;
    return v3++;
}
let a0 = f(true);
print(a0);

for (let i = 0; i < 0x4000; i++) { f(); }

let a3 = f(true);
print(a3);
