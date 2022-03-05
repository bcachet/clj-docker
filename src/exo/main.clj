(ns exo.main
  (:require [exo.add :refer [sum]])
  (:gen-class))

(defn -main
  [& args]
  (println (apply sum (map bigint args)))
  (System/exit 0))