const yaml = require('js-yaml');
const fs = require('fs');

module.exports.readVersion = function (contents) {
    const doc = yaml.load(contents);
    // Restituisce solo la parte semantica (es. 1.0.0) ignorando il +1
    return doc.version.split('+')[0];
};

module.exports.writeVersion = function (contents, version) {
    const doc = yaml.load(contents);
    const oldVersion = doc.version;
    const parts = oldVersion.split('+');

    // Incrementiamo il build number (la parte dopo il +) di 1
    const buildNumber = parts.length > 1 ? parseInt(parts[1]) + 1 : 1;

    // Componiamo la nuova stringa: es. 1.1.0+43
    doc.version = `${version}+${buildNumber}`;

    // Salviamo il file mantenendo lo stile originale
    return yaml.dump(doc, { lineWidth: -1 });
};