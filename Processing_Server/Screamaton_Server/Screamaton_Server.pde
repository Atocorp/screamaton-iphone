import java.net.*;
import java.io.*;

ServerSocket server;
PImage currentPhoto;
String lastMessage = "En attente...";
String photoFolder; // 🆕 Dossier pour les photos
int photoCounter = 1; // 🆕 Compteur pour numéroter les photos

void setup() {
  fullScreen();
  background(0);
  
  // 🆕 Créer le dossier "ScreamPhotos" dans le dossier du sketch
  photoFolder = sketchPath("ScreamPhotos");
  File folder = new File(photoFolder);
  if (!folder.exists()) {
    boolean created = folder.mkdirs();
    if (created) {
      println("📁 Dossier créé: " + photoFolder);
    } else {
      println("❌ Impossible de créer le dossier");
    }
  } else {
    println("📁 Dossier existant: " + photoFolder);
  }
  
  // 🆕 Compter les photos existantes pour continuer la numérotation
  String[] existingFiles = folder.list();
  if (existingFiles != null) {
    photoCounter = existingFiles.length + 1;
    println("📸 Prochaine photo: #" + photoCounter);
  }
  
  thread("startServer");
  println("🚀 Serveur Processing démarré");
  println("💾 Photos sauvegardées dans: " + photoFolder);
}

void draw() {
  background(0);
  
  // Afficher l'image
  if (currentPhoto != null) {
    imageMode(CENTER);
    float ratio = min((float)width / currentPhoto.width, (float)height / currentPhoto.height);
    image(currentPhoto, width/2, height/2, currentPhoto.width * ratio, currentPhoto.height * ratio);
  }
  
  // Afficher le statut en haut
  fill(255);
  textAlign(LEFT);
  textSize(24);
  text("📡 " + lastMessage, 20, 40);
  text("🕐 " + hour() + ":" + nf(minute(), 2) + ":" + nf(second(), 2), 20, 70);
  text("📸 Photos: " + (photoCounter - 1), 20, 100); // 🆕 Compteur affiché
  
  // Instructions en bas
  if (currentPhoto == null) {
    textAlign(CENTER);
    textSize(32);
    fill(100);
    text("📱 En attente d'une photo depuis l'iPhone...", width/2, height/2);
    textSize(20);
    text("IP Mac: Trouvez votre IP avec ifconfig", width/2, height/2 + 50);
    text("📁 Dossier: " + photoFolder, width/2, height/2 + 80);
  }
}

void startServer() {
  try {
    server = new ServerSocket(8080);
    lastMessage = "Serveur actif sur port 8080";
    println("✅ Serveur en écoute sur le port 8080");
    
    while (true) {
      Socket client = server.accept();
      lastMessage = "📱 Connexion iPhone détectée!";
      println("📱 Connexion reçue de: " + client.getInetAddress());
      
      new Thread(() -> handleClient(client)).start();
    }
  } catch (IOException e) {
    lastMessage = "❌ Erreur serveur: " + e.getMessage();
    e.printStackTrace();
  }
}

void handleClient(Socket client) {
  try {
    InputStream inputStream = client.getInputStream();
    
    // Lire les headers HTTP
    String headers = "";
    int b;
    boolean inHeaders = true;
    
    while (inHeaders && (b = inputStream.read()) != -1) {
      headers += (char)b;
      if (headers.endsWith("\r\n\r\n")) {
        inHeaders = false;
      }
    }
    
    // Extraire Content-Length
    int contentLength = 0;
    String[] headerLines = headers.split("\r\n");
    for (String line : headerLines) {
      if (line.toLowerCase().startsWith("content-length:")) {
        contentLength = Integer.parseInt(line.substring(15).trim());
        break;
      }
    }
    
    println("📦 Taille: " + contentLength + " bytes");
    
    if (contentLength > 0) {
      // Lire l'image
      byte[] imageData = new byte[contentLength];
      int totalRead = 0;
      
      while (totalRead < contentLength) {
        int bytesRead = inputStream.read(imageData, totalRead, contentLength - totalRead);
        if (bytesRead == -1) break;
        totalRead += bytesRead;
      }
      
      println("✅ Image reçue: " + totalRead + " bytes");
      
      // 🆕 SAUVEGARDER dans le dossier ScreamPhotos
      try {
        // Nom de fichier avec numéro + timestamp
        String filename = photoFolder + File.separator + 
                         "scream_" + nf(photoCounter, 4) + "_" + 
                         year() + nf(month(),2) + nf(day(),2) + "_" + 
                         nf(hour(),2) + nf(minute(),2) + nf(second(),2) + ".jpg";
        
        println("💾 Sauvegarde: " + filename);
        
        FileOutputStream fos = new FileOutputStream(filename);
        fos.write(imageData);
        fos.close();
        
        // Charger l'image pour l'affichage
        currentPhoto = loadImage(filename);
        
        println("🖼️ Photo #" + photoCounter + " sauvegardée et affichée!");
        lastMessage = "🖼️ Photo #" + photoCounter + " sauvegardée!";
        
        photoCounter++; // Incrémenter pour la prochaine photo
        
      } catch (Exception e) {
        println("❌ Erreur sauvegarde: " + e.getMessage());
        lastMessage = "❌ Erreur sauvegarde: " + e.getMessage();
        
        // 🆕 Plan B: Affichage direct si sauvegarde impossible
        try {
          File tempFile = File.createTempFile("scream_temp", ".jpg");
          FileOutputStream fos = new FileOutputStream(tempFile);
          fos.write(imageData);
          fos.close();
          
          currentPhoto = loadImage(tempFile.getAbsolutePath());
          tempFile.delete();
          
          lastMessage = "🖼️ Photo affichée (sauvegarde échouée)";
        } catch (Exception e2) {
          lastMessage = "❌ Erreur complète: " + e2.getMessage();
        }
      }
      
    } else if (headers.contains("GET")) {
      // Test de connexion
      lastMessage = "🧪 Test de connexion OK";
      println("🧪 Test de connexion iPhone");
      
      String response = "HTTP/1.1 200 OK\r\n";
      response += "Content-Type: text/plain\r\n";
      response += "Content-Length: 25\r\n\r\n";
      response += "✅ Processing connecté!";
      
      client.getOutputStream().write(response.getBytes());
    }
    
    client.close();
    
  } catch (Exception e) {
    lastMessage = "❌ Erreur: " + e.getMessage();
    println("❌ Erreur: " + e.getMessage());
  }
}

// 🆕 BONUS: Fonction pour ouvrir le dossier (optionnel)
void keyPressed() {
  if (key == 'o' || key == 'O') {
    // Ouvrir le dossier ScreamPhotos dans le Finder (Mac)
    try {
      Runtime.getRuntime().exec("open " + photoFolder);
      println("📁 Ouverture du dossier: " + photoFolder);
    } catch (Exception e) {
      println("❌ Impossible d'ouvrir le dossier");
    }
  }
  
  if (key == 'c' || key == 'C') {
    // Effacer l'image affichée
    currentPhoto = null;
    lastMessage = "🧹 Écran effacé";
    println("🧹 Écran effacé");
  }
}
