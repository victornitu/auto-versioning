const fs = require('fs')

function copy(src, dst) {
    return new Promise(resolve => {
        console.log('Copy', src, 'to', dst)
        fs.copyFile(src, dst, err => {
            if (err) throw err
            console.log('Done:', src, 'copied to', dst)
            resolve()
        })
    })
}

console.log('*** Start Init ***')
Promise.all([
    copy('hooks/post-checkout', '.git/hooks/post-checkout'),
    copy('hooks/pre-push', '.git/hooks/pre-push')
]).then(() => console.log('*** Init Done ***'))

